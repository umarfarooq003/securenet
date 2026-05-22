import 'package:flutter/material.dart';
import '../services/graphql_service.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

class Node {
  final String nodeId;
  final String nodeType;
  final String name;
  final String ip;
  final String status;
  final dynamic allProperties;

  const Node({
    required this.nodeId,
    required this.nodeType,
    required this.name,
    required this.ip,
    required this.status,
    required this.allProperties,
  });

  factory Node.fromJson(Map<String, dynamic> json) => Node(
        nodeId: (json['nodeId'] ?? '').toString(),
        nodeType: (json['nodeType'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        ip: (json['ipAddress'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        allProperties: json['allProperties'],
      );
}

class NodeListPage extends StatefulWidget {
  const NodeListPage({super.key});

  @override
  State<NodeListPage> createState() => _NodeListPageState();
}

class _NodeListPageState extends State<NodeListPage> {
  List<Node> nodes = [];
  List<Node> filtered = [];
  final GraphQLService _service = GraphQLService();
  final _searchCtrl = TextEditingController();
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNodes();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      filtered = q.isEmpty
          ? List.from(nodes)
          : nodes
              .where((n) =>
                  n.name.toLowerCase().contains(q) ||
                  n.nodeType.toLowerCase().contains(q) ||
                  n.ip.toLowerCase().contains(q) ||
                  n.status.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> fetchNodes() async {
    if (mounted) setState(() { isLoading = true; errorMessage = null; });
    try {
      final list = await _service.fetchNodes();
      if (!mounted) return;
      setState(() {
        nodes    = list.map((n) => Node.fromJson(n)).toList();
        filtered = List.from(nodes);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { errorMessage = e.toString(); isLoading = false; });
    }
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('router'))   return Icons.router_rounded;
    if (t.contains('switch'))   return Icons.device_hub_rounded;
    if (t.contains('server'))   return Icons.dns_rounded;
    if (t.contains('endpoint') || t.contains('device')) return Icons.laptop_rounded;
    return Icons.devices_other_rounded;
  }

  Color _colorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('router'))   return AppTheme.statusBlue;
    if (t.contains('switch'))   return AppTheme.statusPurple;
    if (t.contains('server'))   return const Color(0xFF0EA5E9);
    return AppTheme.brandTeal;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: fetchNodes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, type, IP or status…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Count chip
          if (!isLoading && errorMessage == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('${filtered.length} device${filtered.length != 1 ? 's' : ''}'),
                  avatar: Icon(Icons.devices_rounded, size: 14, color: scheme.primary),
                ),
              ),
            ),

          // Content
          Expanded(
            child: isLoading
                ? const LoadingOverlay(label: 'Loading devices…')
                : errorMessage != null
                    ? ErrorState(message: errorMessage!, onRetry: fetchNodes)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.device_unknown_rounded,
                            title: _searchCtrl.text.isNotEmpty
                                ? 'No results for "${_searchCtrl.text}"'
                                : 'No devices found',
                            subtitle: 'Pull down to refresh or adjust your search.',
                            action: _searchCtrl.text.isNotEmpty
                                ? TextButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _applyFilter();
                                    },
                                    child: const Text('Clear search'),
                                  )
                                : null,
                          )
                        : RefreshIndicator(
                            onRefresh: fetchNodes,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.88,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final n = filtered[i];
                                return buildDeviceCard(
                                  ctx,
                                  icon: _iconForType(n.nodeType),
                                  color: _colorForType(n.nodeType),
                                  title: n.name.isNotEmpty ? n.name : 'Node ${n.nodeId}',
                                  type: n.nodeType,
                                  ip: n.ip,
                                  status: n.status,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}