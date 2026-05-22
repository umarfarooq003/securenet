// lib/messa/providers/simulation_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sim_config.dart';
import '../models/step_result.dart';
import '../services/messa_api_service.dart';

enum SimStatus { idle, loading, running, done, error }

enum ConnStatus { unknown, checking, ok, failed }

class SimulationProvider extends ChangeNotifier {
  MessaApiService _api;

  SimulationProvider() : _api = MessaApiService();

  // ── connection ─────────────────────────────────────────────────────────────
  String serverUrl = 'https://messaapi.vercel.app';
  ConnStatus connStatus = ConnStatus.unknown;

  // ── public state ───────────────────────────────────────────────────────────
  SimStatus status = SimStatus.idle;
  StepResult? result;
  String errorMessage = '';
  SimConfig config = const SimConfig();
  bool _stopRequested = false;

  // ── topology & layout ──────────────────────────────────────────────────────
  List<dynamic> topologyEdges = [];      // [{source, target}]
  List<dynamic> topologyNodes = [];      // [{id, name, type, ip}]
  Map<int, Offset> nodePositions = {};   // normalised 0..1

  // ── chart history ──────────────────────────────────────────────────────────
  final List<int> infectedHistory  = [];
  final List<int> healthyHistory   = [];
  final List<int> recoveredHistory = [];
  final List<int> resistantHistory = [];
  final List<int> stepHistory      = [];

  bool get hasResult  => result != null;
  bool get isRunning  => status == SimStatus.running;
  bool get isDone     => status == SimStatus.done;

  // ── update server URL ──────────────────────────────────────────────────────
  void updateServerUrl(String url) {
    serverUrl = url.trim();
    _api = MessaApiService(baseUrl: serverUrl);
    connStatus = ConnStatus.unknown;
    notifyListeners();
  }

  // ── test connection ────────────────────────────────────────────────────────
  Future<void> testConnection() async {
    if (serverUrl.isEmpty) {
      errorMessage = 'Please enter the server URL first.';
      connStatus = ConnStatus.failed;
      notifyListeners();
      return;
    }
    connStatus = ConnStatus.checking;
    errorMessage = '';
    notifyListeners();
    final ok = await _api.isReachable();
    connStatus = ok ? ConnStatus.ok : ConnStatus.failed;
    if (!ok) {
      errorMessage =
          'Cannot reach the backend at:\n$serverUrl\n\n'
          'Make sure your friend started it with:\n';
    }
    notifyListeners();
  }

  // ── config ─────────────────────────────────────────────────────────────────
  void updateConfig(SimConfig c) {
    config = c;
    notifyListeners();
  }

  // ── run full simulation ────────────────────────────────────────────────────
  // NOTE: Vercel is STATELESS — global _model resets on every request.
  //       So we use /simulation/run which completes the entire simulation
  //       in ONE HTTP call and returns all steps. We then replay them locally
  //       with a delay so the UI animates step-by-step.
  Future<void> runSimulation() async {
    // Guard: need a URL
    if (serverUrl.isEmpty) {
      errorMessage = 'Please enter and test the server URL first.';
      status = SimStatus.error;
      notifyListeners();
      return;
    }

    _stopRequested = false;
    status = SimStatus.loading;
    errorMessage = '';
    _clearHistory();
    notifyListeners();

    try {
      // Single API call → get ALL steps at once
      final response = await _api.runFullSimulation(config, maxSteps: 100);

      final stepsList = response['steps'] as List? ?? [];
      if (stepsList.isEmpty) {
        throw Exception('Simulation returned no steps. Check backend logs.');
      }

      // Extract topology from first step's devices
      final firstStep = stepsList.first as Map<String, dynamic>;
      final devices = firstStep['devices'] as List? ?? [];
      topologyNodes = devices
          .map((d) => {
                'id':   d['id'],
                'name': d['name'],
                'type': d['device_type'],
                'ip':   d['ip'],
              })
          .toList();

      // Build edges from connections in first step
      final edgesSet = <String>{};
      final edgesList = <Map<String, dynamic>>[];
      for (final d in devices) {
        final srcId = d['id'] as int;
        final conns = d['connections'] as List? ?? [];
        for (final tgtId in conns) {
          final key = srcId < tgtId
              ? '$srcId-$tgtId'
              : '${tgtId}-$srcId';
          if (edgesSet.add(key)) {
            edgesList.add({'source': srcId, 'target': tgtId});
          }
        }
      }
      topologyEdges = edgesList;
      _computeLayout();

      connStatus = ConnStatus.ok;
      status = SimStatus.running;
      notifyListeners();

      // Replay each step locally with UI animation delay
      final delayMs =
          (800 / config.simulationSpeed).round().clamp(50, 2000);

      for (final stepData in stepsList) {
        if (_stopRequested) break;

        result = StepResult.fromJson(stepData as Map<String, dynamic>);
        _recordHistory();
        notifyListeners();

        await Future.delayed(Duration(milliseconds: delayMs));
      }

      status = SimStatus.done;
    } catch (e) {
      errorMessage = _friendlyError(e.toString());
      connStatus = ConnStatus.failed;
      status = SimStatus.error;
    }
    notifyListeners();
  }

  // ── stop mid-run ───────────────────────────────────────────────────────────
  void stopSimulation() => _stopRequested = true;

  // ── reset ──────────────────────────────────────────────────────────────────
  Future<void> reset() async {
    _stopRequested = true;
    await Future.delayed(const Duration(milliseconds: 120));
    try {
      await _api.reset();
    } catch (_) {}
    result = null;
    errorMessage = '';
    connStatus = ConnStatus.unknown;
    topologyEdges = [];
    topologyNodes = [];
    nodePositions = {};
    _clearHistory();
    status = SimStatus.idle;
    notifyListeners();
  }

  // ── CSV export ─────────────────────────────────────────────────────────────
  Future<String?> exportCsv() async {
    if (stepHistory.isEmpty) return null;

    // Build header + rows
    final sb = StringBuffer();
    sb.writeln(
        'Step,Infected,Healthy,Recovered,Resistant,TotalDevices,InfectionRate%');
    final total = result?.totalDevices ?? 1;
    for (int i = 0; i < stepHistory.length; i++) {
      final inf = infectedHistory[i];
      final rate = ((inf / total) * 100).toStringAsFixed(2);
      sb.writeln(
          '${stepHistory[i]},$inf,${healthyHistory[i]},${recoveredHistory[i]},${resistantHistory[i]},$total,$rate');
    }

    // Write to documents folder
    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/messa_simulation_${DateTime.now().millisecondsSinceEpoch}.csv';
    await File(path).writeAsString(sb.toString());
    return path;
  }

  // ── layout computation ─────────────────────────────────────────────────────
  void _computeLayout() {
    // Tier definitions: device type → normalised y position
    const tiers = <String, double>{
      'ISP': 0.04,
      'Router': 0.13,
      'Firewall': 0.22,
      'AggregationSwitch': 0.32,
      'Server': 0.41,
      'Switch': 0.50,
      'AccessPoint': 0.65,
      'Endpoint': 0.84,
    };

    // Group nodes by type
    final byType = <String, List<dynamic>>{};
    for (final n in topologyNodes) {
      final t = (n['type'] as String?) ?? 'Endpoint';
      byType[t] = [...(byType[t] ?? []), n];
    }

    nodePositions = {};
    for (final entry in byType.entries) {
      final type   = entry.key;
      final nodes  = entry.value;
      final y      = tiers[type] ?? 0.5;
      final count  = nodes.length;
      for (int i = 0; i < count; i++) {
        // Distribute horizontally with padding
        final x = (i + 1) / (count + 1);
        nodePositions[(nodes[i]['id'] as int)] = Offset(x, y);
      }
    }
    notifyListeners();
  }

  // ── device-type infection breakdown (for bar chart) ────────────────────────
  Map<String, Map<String, int>> get typeBreakdown {
    final out = <String, Map<String, int>>{};
    if (result == null) return out;
    for (final d in result!.devices) {
      out[d.deviceType] ??= {
        'infected': 0, 'healthy': 0, 'recovered': 0, 'resistant': 0
      };
      if (d.infected)       out[d.deviceType]!['infected'] = out[d.deviceType]!['infected']! + 1;
      else if (d.resistant) out[d.deviceType]!['resistant'] = out[d.deviceType]!['resistant']! + 1;
      else if (d.recovered) out[d.deviceType]!['recovered'] = out[d.deviceType]!['recovered']! + 1;
      else                  out[d.deviceType]!['healthy'] = out[d.deviceType]!['healthy']! + 1;
    }
    return out;
  }

  // ── private helpers ────────────────────────────────────────────────────────
  void _clearHistory() {
    infectedHistory.clear();
    healthyHistory.clear();
    recoveredHistory.clear();
    resistantHistory.clear();
    stepHistory.clear();
  }

  void _recordHistory() {
    if (result == null) return;
    stepHistory.add(result!.step);
    infectedHistory.add(result!.infectedCount);
    healthyHistory.add(result!.healthyCount);
    recoveredHistory.add(result!.recoveredCount);
    resistantHistory.add(result!.resistantCount);
  }

  String _friendlyError(String raw) {
    // Strip the Dart 'Exception: ' wrapper to keep messages clean
    String msg = raw.startsWith('Exception: ') ? raw.substring(11) : raw;

    if (msg.contains('timed-out or crashed') ||
        msg.contains('Vercel timed-out')) {
      return '⏱ Server Timeout\n\n'
          'The simulation took too long to respond.\n'
          'Ask your friend to make sure the server is running:\n';
    }
    if (msg.contains('TimeoutException') ||
        msg.contains('Connection timed out')) {
      return '⏱ Request Timed Out\n\n'
          'The server at $serverUrl is not responding.\n'
          'Check the URL or ask your friend to restart the server.';
    }
    if (msg.contains('Connection refused') ||
        msg.contains('SocketException') ||
        msg.contains('ClientException') ||
        msg.contains('Failed host lookup')) {
      return '🔌 Cannot Connect\n\n'
          'Could not reach: $serverUrl\n\n'
          'Make sure your friend started the server with:\n';
    }
    if (msg.contains('HTTP 5')) {
      return 'Server Error\n\n'
          'The server returned an error'
          'server logs for details.';
    }
    return msg;
  }
}
