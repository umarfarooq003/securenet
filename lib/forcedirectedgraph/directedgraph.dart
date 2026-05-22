import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';

import '../services/graphql_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Neo4j Force-Directed Graph Visualization
// ─────────────────────────────────────────────────────────────────────────────
class Neo4jForceGraphPage extends StatefulWidget {
  @override
  _Neo4jForceGraphPageState createState() => _Neo4jForceGraphPageState();
}

class _Neo4jForceGraphPageState extends State<Neo4jForceGraphPage> {
  static const int _maxGraphNodes = 180;

  final ForceDirectedGraphController<String> controller =
      ForceDirectedGraphController<String>();
  final GraphQLService _service = GraphQLService();

  final Map<String, Map<String, dynamic>> _nodeDetails = {};
  final Map<String, String> _nodeInfo = {};
  final Set<String> _nodeKeys = {};
  final Set<String> _edgeKeys = {};

  bool isLoading = true;
  String? errorMsg;

  // ── Key Helpers ────────────────────────────────────────────────────────────

  String _nodeKey(Map<String, dynamic> node) {
    final name = (node['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    final nodeId = node['nodeId']?.toString().trim();
    if (nodeId != null && nodeId.isNotEmpty) return nodeId;

    return 'unknown-node-${_nodeDetails.length + 1}';
  }

  String _extractName(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(.*) \((.*)\)$').firstMatch(trimmed);
    if (match != null) {
      return match.group(1)?.trim() ?? trimmed;
    }
    return trimmed;
  }

  String _extractType(String value) {
    final match = RegExp(r'^(.*) \((.*)\)$').firstMatch(value.trim());
    if (match != null) {
      return match.group(2)?.trim() ?? '';
    }
    return '';
  }

  String _edgeKey(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}__${pair[1]}';
  }

  String _nodeTypeKey(Map<String, dynamic> node) {
    return (node['nodeType'] ?? '').toString().toLowerCase().trim();
  }

  String? _extractApFromProperties(Map<String, dynamic> node) {
    final props = (node['allProperties'] ?? '').toString();
    if (props.isEmpty) return null;

    final singleQuoteMatch = RegExp(r"'AP'\s*:\s*'([^']+)'").firstMatch(props);
    if (singleQuoteMatch != null) {
      final value = singleQuoteMatch.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final doubleQuoteMatch = RegExp(r'"AP"\s*:\s*"([^"]+)"').firstMatch(props);
    if (doubleQuoteMatch != null) {
      final value = doubleQuoteMatch.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }

  // ── Graph Mutation Helpers ─────────────────────────────────────────────────

  void _connectRoundRobin(List<String> sourceNodes, List<String> targetNodes) {
    if (sourceNodes.isEmpty || targetNodes.isEmpty) return;

    for (var i = 0; i < sourceNodes.length; i++) {
      _addEdgeSafe(sourceNodes[i], targetNodes[i % targetNodes.length]);
    }
  }

  void _registerNode(Map<String, dynamic> node) {
    if (_nodeDetails.length >= _maxGraphNodes) return;

    final key = _nodeKey(node);
    if (_nodeKeys.contains(key)) return;

    _nodeKeys.add(key);
    _nodeDetails[key] = node;
    try {
      controller.addNode(key);
    } catch (_) {
      // Ignore duplicate insertions from overlapping datasets.
    }
  }

  void _ensureNodeExists(
    String name, {
    String? nodeType,
    String? status,
    dynamic allProperties,
  }) {
    if (name.isEmpty || _nodeKeys.contains(name)) return;
    if (_nodeDetails.length >= _maxGraphNodes) return;

    _nodeKeys.add(name);
    _nodeDetails[name] = {
      'name': name,
      'nodeType': nodeType ?? 'Unknown',
      'status': status,
      'allProperties': allProperties,
    };

    try {
      controller.addNode(name);
    } catch (_) {
      // Ignore duplicate insertions from overlapping datasets.
    }
  }

  void _addEdgeSafe(String a, String b) {
    if (a.isEmpty || b.isEmpty || a == b) return;

    final key = _edgeKey(a, b);
    if (_edgeKeys.contains(key)) return;

    try {
      final nodeA = controller.graph.nodes.firstWhere(
        (element) => element.data == a,
        orElse: () => throw StateError('Missing node: $a'),
      );
      final nodeB = controller.graph.nodes.firstWhere(
        (element) => element.data == b,
        orElse: () => throw StateError('Missing node: $b'),
      );

      controller.addEdgeByNode(nodeA, nodeB);
      _edgeKeys.add(key);
    } catch (_) {
      // Ignore missing-node and duplicate-edge cases.
    }
  }

  // ── Styling Helpers ────────────────────────────────────────────────────────

  Color _getNodeColor(Map<String, dynamic> node) {
    final lowerName = (node['name'] ?? '').toString().toLowerCase();
    final lowerType = (node['nodeType'] ?? '').toString().toLowerCase();
    final lowerStatus = (node['status'] ?? '').toString().toLowerCase();

    if (lowerStatus.contains('infected') || lowerStatus.contains('suspected')) {
      return const Color(0xFFEF4444); // red
    }
    if (lowerType.contains('router') || lowerName.contains('router')) {
      return const Color(0xFF3B82F6); // blue
    }
    if (lowerType.contains('switch') || lowerName.contains('switch')) {
      return const Color(0xFF10B981); // green
    }
    if (lowerType.contains('endpoint') ||
        lowerName.contains('endpoint') ||
        lowerName.contains('device')) {
      return const Color(0xFFF59E0B); // amber
    }
    if (lowerType.contains('server') || lowerName.contains('server')) {
      return const Color(0xFF6366F1); // indigo
    }
    if (lowerType.contains('loadbalancer') ||
        lowerName.contains('loadbalancer') ||
        (lowerName.contains('load') && lowerName.contains('balancer'))) {
      return const Color(0xFF14B8A6); // teal
    }

    return const Color(0xFF8B5CF6); // purple
  }

  String _getNodeInfo(Map<String, dynamic> node) {
    final buf = StringBuffer();
    if (node['name'] != null) buf.writeln('Name: ${node['name']}');
    if (node['nodeId'] != null) buf.writeln('Node ID: ${node['nodeId']}');
    if (node['nodeType'] != null) buf.writeln('Type: ${node['nodeType']}');
    if (node['ipAddress'] != null) buf.writeln('IP: ${node['ipAddress']}');
    if (node['mac'] != null) buf.writeln('MAC: ${node['mac']}');
    if (node['macAddress'] != null) buf.writeln('MAC: ${node['macAddress']}');
    if (node['status'] != null) buf.writeln('Status: ${node['status']}');
    if (node['allProperties'] != null) {
      buf.writeln('Properties: ${node['allProperties']}');
    }
    return buf.toString().trim();
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    fetchGraphData();
  }

  Future<void> fetchGraphData() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final nodes = await _service.fetchNodes();
      final switchNodes = await _service.fetchSwitches();
      final indirectRisks = await _service.fetchIndirectRisks();

      controller.graph.nodes.clear();
      controller.graph.edges.clear();
      _nodeDetails.clear();
      _nodeInfo.clear();
      _nodeKeys.clear();
      _edgeKeys.clear();

      for (final node in nodes) {
        _registerNode(node);
      }

      for (final switchNode in switchNodes) {
        final switchName = (switchNode['name'] ?? '').toString().trim();
        if (switchName.isEmpty) continue;

        _ensureNodeExists(
          switchName,
          nodeType: 'Switch',
          allProperties: switchNode,
        );

        final devices = await _service.fetchDevicesBySwitch(switchName);
        for (final device in devices) {
          final deviceName = (device['name'] ?? '').toString().trim();
          if (deviceName.isEmpty) continue;

          _ensureNodeExists(
            deviceName,
            nodeType: 'Endpoint',
            allProperties: device,
          );
          _addEdgeSafe(switchName, deviceName);
        }
      }

      for (final risk in indirectRisks) {
        final source = _extractName((risk['source'] ?? '').toString());
        final mediator = _extractName((risk['mediator'] ?? '').toString());
        final target = _extractName((risk['target'] ?? '').toString());

        _ensureNodeExists(
          source,
          nodeType: _extractType((risk['source'] ?? '').toString()),
          status: risk['riskType']?.toString(),
          allProperties: risk,
        );
        _ensureNodeExists(
          mediator,
          nodeType: _extractType((risk['mediator'] ?? '').toString()),
          status: risk['riskType']?.toString(),
          allProperties: risk,
        );
        _ensureNodeExists(
          target,
          nodeType: _extractType((risk['target'] ?? '').toString()),
          status: risk['riskType']?.toString(),
          allProperties: risk,
        );

        _addEdgeSafe(source, mediator);
        _addEdgeSafe(mediator, target);
      }

      final entries = _nodeDetails.entries.toList();

      final endpoints = <String>[];
      final accessPoints = <String>[];
      final switches = <String>[];
      final serverSwitches = <String>[];
      final aggregationSwitches = <String>[];
      final routers = <String>[];
      final firewalls = <String>[];
      final isps = <String>[];
      final servers = <String>[];

      for (final entry in entries) {
        final name = entry.key;
        final node = entry.value;
        final type = _nodeTypeKey(node);
        final lowerName = name.toLowerCase();

        if (type.contains('endpoint')) {
          endpoints.add(name);
        } else if (type.contains('accesspoint')) {
          accessPoints.add(name);
        } else if (type.contains('aggregationswitch')) {
          aggregationSwitches.add(name);
        } else if (type.contains('switch')) {
          if (lowerName.contains('serverswitch')) {
            serverSwitches.add(name);
          } else {
            switches.add(name);
          }
        } else if (type.contains('router')) {
          routers.add(name);
        } else if (type.contains('firewall')) {
          firewalls.add(name);
        } else if (type.contains('isp')) {
          isps.add(name);
        } else if (type.contains('server')) {
          servers.add(name);
        }
      }

      var fallbackIndex = 0;
      for (final endpointName in endpoints) {
        final endpoint = _nodeDetails[endpointName];
        if (endpoint == null) continue;

        final apName = _extractApFromProperties(endpoint);
        if (apName != null && _nodeKeys.contains(apName)) {
          _addEdgeSafe(endpointName, apName);
        } else if (switches.isNotEmpty) {
          _addEdgeSafe(endpointName, switches[fallbackIndex % switches.length]);
          fallbackIndex++;
        }
      }

      _connectRoundRobin(accessPoints, switches);
      _connectRoundRobin(switches, aggregationSwitches);
      _connectRoundRobin(aggregationSwitches, routers);
      _connectRoundRobin(routers, isps);
      _connectRoundRobin(serverSwitches, firewalls);
      _connectRoundRobin(firewalls, servers);
      _connectRoundRobin(servers, serverSwitches);

      if (!mounted) return;
      setState(() {
        isLoading = false;
        if (_nodeDetails.isEmpty) {
          errorMsg = 'No graph data available from backend.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = 'Exception: $e';
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Neo4j Graph'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Graph',
            onPressed: fetchGraphData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Building graph…',
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
              : errorMsg != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: scheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMsg!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: fetchGraphData,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ForceDirectedGraphWidget<String>(
                      controller: controller,
                      nodesBuilder: (context, nodeData) {
                        final node = _nodeDetails[nodeData];
                        if (node == null) return const SizedBox.shrink();

                        final nodeColor = _getNodeColor(node);
                        final isSelected = _nodeInfo.containsKey(nodeData);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _nodeInfo.clear();
                              _nodeInfo[nodeData] = _getNodeInfo(node);
                            });

                            Future.delayed(const Duration(seconds: 3), () {
                              if (!mounted) return;
                              setState(() {
                                _nodeInfo.remove(nodeData);
                              });
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? const Color(0xFF1E3A52)
                                            : Colors.white,
                                    border: Border.all(
                                      color: nodeColor.withOpacity(0.55),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _nodeInfo[nodeData] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.4,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              Container(
                                width: isSelected ? 28 : 22,
                                height: isSelected ? 28 : 22,
                                decoration: BoxDecoration(
                                  color: nodeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : nodeColor.withOpacity(0.4),
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: nodeColor.withOpacity(
                                        isSelected ? 0.55 : 0.25,
                                      ),
                                      blurRadius: isSelected ? 10 : 4,
                                      spreadRadius: isSelected ? 1 : 0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      edgesBuilder: (context, a, b, distance) {
                        return Container(
                          width: distance > 8 ? distance : 8,
                          height: 1.8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                scheme.primary.withOpacity(0.65),
                                scheme.tertiary.withOpacity(0.35),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: scheme.outline.withOpacity(0.25),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _legendItem('Routers', const Color(0xFF3B82F6), scheme),
                        _legendItem(
                          'Switches',
                          const Color(0xFF10B981),
                          scheme,
                        ),
                        _legendItem(
                          'Endpoints',
                          const Color(0xFFF59E0B),
                          scheme,
                        ),
                        _legendItem('Servers', const Color(0xFF6366F1), scheme),
                        _legendItem(
                          'LoadBalancers',
                          const Color(0xFF14B8A6),
                          scheme,
                        ),
                        _legendItem(
                          'Suspected',
                          const Color(0xFFEF4444),
                          scheme,
                        ),
                        _legendItem('Others', const Color(0xFF8B5CF6), scheme),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _legendItem(String label, Color color, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
