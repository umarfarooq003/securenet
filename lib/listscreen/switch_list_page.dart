import 'package:flutter/material.dart';
import '../services/graphql_service.dart';
import '../widgets/shared_widgets.dart';

class NetworkSwitch {
  final String name;
  final String mac;
  const NetworkSwitch({required this.name, required this.mac});
  factory NetworkSwitch.fromJson(Map<String, dynamic> json) => NetworkSwitch(
        name: (json['name'] ?? '').toString(),
        mac: (json['mac'] ?? '').toString(),
      );
}

class SwitchListPage extends StatefulWidget {
  const SwitchListPage({super.key});
  @override
  State<SwitchListPage> createState() => _SwitchListPageState();
}

class _SwitchListPageState extends State<SwitchListPage> {
  List<NetworkSwitch> switches  = [];
  List<NetworkSwitch> filtered  = [];
  final GraphQLService _service = GraphQLService();
  final _searchCtrl = TextEditingController();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSwitches();
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
          ? List.from(switches)
          : switches
              .where((s) =>
                  s.name.toLowerCase().contains(q) ||
                  s.mac.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> fetchSwitches() async {
    if (mounted) setState(() { isLoading = true; errorMessage = null; });
    try {
      final list = await _service.fetchSwitches();
      if (!mounted) return;
      setState(() {
        switches = list.map((s) => NetworkSwitch.fromJson(s)).toList();
        filtered = List.from(switches);
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
    const switchColor = Color(0xFF8B5CF6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Switches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: fetchSwitches,
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
                hintText: 'Search by name or MAC address…',
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
                  label: Text('${filtered.length} switch${filtered.length != 1 ? 'es' : ''}'),
                  avatar: Icon(Icons.device_hub_rounded, size: 14, color: scheme.primary),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const LoadingOverlay(label: 'Loading switches…')
                : errorMessage != null
                    ? ErrorState(message: errorMessage!, onRetry: fetchSwitches)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.device_hub_rounded,
                            title: 'No switches found',
                            subtitle: 'Pull down to refresh.',
                          )
                        : RefreshIndicator(
                            onRefresh: fetchSwitches,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final sw = filtered[i];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: switchColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.device_hub_rounded,
                                              color: switchColor, size: 22),
                                        ),
                                        const Spacer(),
                                        Text(
                                          sw.name,
                                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sw.mac.isNotEmpty ? sw.mac : 'MAC: —',
                                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                                color: scheme.onSurface.withOpacity(0.5),
                                                fontFamily: 'monospace',
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
