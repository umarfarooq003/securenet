// lib/messa/services/messa_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sim_config.dart';
import '../models/step_result.dart';

class MessaApiService {
  final String baseUrl;

  MessaApiService({this.baseUrl = 'https://messaapi.vercel.app'});

  // ── health ──────────────────────────────────────────────────────────────────
  Future<bool> isReachable() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200 || _isHtml(res.body)) return false;
      // Verify messa actually loaded on the server (not just HTTP 200)
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  // ── setup ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> setup(SimConfig config) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/simulation/setup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(config.toJson()),
        )
        .timeout(const Duration(seconds: 30));
    _assertOk(res, 'setup');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── step ────────────────────────────────────────────────────────────────────
  Future<StepResult> stepOnce() async {
    final res = await http
        .post(Uri.parse('$baseUrl/simulation/step'))
        .timeout(const Duration(seconds: 30));
    _assertOk(res, 'step');
    return StepResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── status ──────────────────────────────────────────────────────────────────
  Future<StepResult> getStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/simulation/status'))
        .timeout(const Duration(seconds: 15));
    _assertOk(res, 'status');
    return StepResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── reset ───────────────────────────────────────────────────────────────────
  Future<void> reset() async {
    final res = await http
        .post(Uri.parse('$baseUrl/simulation/reset'))
        .timeout(const Duration(seconds: 15));
    _assertOk(res, 'reset');
  }

  // ── topology ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTopology() async {
    final res = await http
        .get(Uri.parse('$baseUrl/simulation/topology'))
        .timeout(const Duration(seconds: 30));
    _assertOk(res, 'topology');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── run full simulation in ONE call (Vercel-compatible) ─────────────────────
  // Vercel free tier has a 10-second function timeout.
  // We keep max_steps small (≤20) to stay under the limit.
  Future<Map<String, dynamic>> runFullSimulation(
    SimConfig config, {
    int maxSteps = 20,
  }) async {
    final body = {
      ...config.toJson(),
      'max_steps': maxSteps,
    };
    final res = await http
        .post(
          Uri.parse('$baseUrl/simulation/run'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));
    _assertOk(res, 'run');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── private ─────────────────────────────────────────────────────────────────

  /// Returns true when Vercel sends back an HTML error/timeout page
  /// instead of JSON (happens on 504 Gateway Timeout, 500, etc.)
  bool _isHtml(String body) {
    final trimmed = body.trimLeft();
    return trimmed.startsWith('<!') || trimmed.startsWith('<html');
  }

  void _assertOk(http.Response res, String endpoint) {
    if (_isHtml(res.body)) {
      // Vercel returned an HTML error page — likely a timeout (504)
      throw Exception(
        '[$endpoint] Vercel timed-out or crashed.\n'
        'The simulation is too heavy for the free Vercel serverless tier.\n'
        'Try reducing max_steps or use a local/paid server.\n'
        '(HTTP ${res.statusCode})',
      );
    }
    if (res.statusCode != 200) {
      throw Exception('[$endpoint] HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
