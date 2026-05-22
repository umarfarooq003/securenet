import 'package:flutter/material.dart';
import '../services/graphql_service.dart';
import '../widgets/shared_widgets.dart';

class Server {
  final String name;
  const Server({required this.name});
  factory Server.fromJson(Map<String, dynamic> json) =>
      Server(name: (json['name'] ?? '').toString());
}

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});
  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  List<Server> servers  = [];
  List<Server> filtered = [];
  final GraphQLService _service  = GraphQLService();
  final _searchCtrl = TextEditingController();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchServers();
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
          ? List.from(servers)
          : servers.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> fetchServers() async {
    if (mounted) setState(() { isLoading = true; errorMessage = null; });
    try {
      final list = await _service.fetchServers();
      if (!mounted) return;
      setState(() {
        servers  = list.map((s) => Server.fromJson(s)).toList();
        filtered = List.from(servers);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { errorMessage = e.toString(); isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: fetchServers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search servers…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () { _searchCtrl.clear(); _applyFilter(); },
                      )
                    : null,
              ),
            ),
          ),
          if (!isLoading && errorMessage == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('${filtered.length} server${filtered.length != 1 ? 's' : ''}'),
                  avatar: Icon(Icons.dns_rounded, size: 14, color: scheme.primary),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const LoadingOverlay(label: 'Loading servers…')
                : errorMessage != null
                    ? ErrorState(message: errorMessage!, onRetry: fetchServers)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.dns_rounded,
                            title: 'No servers found',
                            subtitle: 'Pull down to refresh or check your connection.',
                          )
                        : RefreshIndicator(
                            onRefresh: fetchServers,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final server = filtered[i];
                                return Card(
                                  child: InkWell(
                                    onTap: () {},
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0EA5E9).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.dns_rounded,
                                                color: Color(0xFF0EA5E9), size: 22),
                                          ),
                                          const Spacer(),
                                          Text(
                                            server.name,
                                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Server',
                                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                                  color: scheme.onSurface.withOpacity(0.5),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
