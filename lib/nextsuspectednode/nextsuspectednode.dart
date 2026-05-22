import 'package:flutter/material.dart';
import '../services/graphql_service.dart';
import '../widgets/shared_widgets.dart';

class RiskJsonPage extends StatefulWidget {
  const RiskJsonPage({super.key});
  @override
  State<RiskJsonPage> createState() => _RiskJsonPageState();
}

class _RiskJsonPageState extends State<RiskJsonPage> {
  final GraphQLService _service = GraphQLService();
  bool isLoading = true;
  String? errorMsg;
  List<dynamic>? indirectRisks;
  final _searchCtrl = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    fetchJsonData();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    if (indirectRisks == null) return;
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(indirectRisks!)
          : indirectRisks!.where((r) {
              return (r['source'] ?? '').toString().toLowerCase().contains(q) ||
                  (r['target'] ?? '').toString().toLowerCase().contains(q) ||
                  (r['mediator'] ?? '').toString().toLowerCase().contains(q) ||
                  (r['riskType'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> fetchJsonData() async {
    if (mounted) setState(() { isLoading = true; errorMsg = null; });
    try {
      final risks = await _service.fetchIndirectRisks();
      if (mounted) {
        setState(() {
          indirectRisks = risks;
          _filtered = List.from(risks);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; errorMsg = 'Failed to load data: $e'; });
    }
  }

  Color _riskColor(String riskType) {
    final r = riskType.toLowerCase();
    if (r.contains('high') || r.contains('critical')) return const Color(0xFFEF4444);
    if (r.contains('medium')) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: fetchJsonData,
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
                hintText: 'Search by source, target, mediator…',
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

          // Summary chips
          if (!isLoading && errorMsg == null && indirectRisks != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Chip(
                    label: Text('${_filtered.length} risks'),
                    avatar: Icon(Icons.warning_amber_rounded, size: 14, color: scheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      'Total: ${indirectRisks!.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: isLoading
                ? const LoadingOverlay(label: 'Analysing risks…')
                : errorMsg != null
                    ? ErrorState(message: errorMsg!, onRetry: fetchJsonData)
                    : _filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.verified_user_rounded,
                            title: 'No risks found',
                            subtitle: 'No indirect risk paths detected in the current network.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final risk = _filtered[i];
                              final riskType = (risk['riskType'] ?? '').toString();
                              final rc = _riskColor(riskType);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Risk type badge + row header
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: rc.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.warning_amber_rounded, color: rc, size: 18),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              riskType.isNotEmpty ? riskType : 'Unknown Risk',
                                              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: rc,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            '#${i + 1}',
                                            style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                                  color: scheme.onSurface.withOpacity(0.4),
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Path visualizer
                                      _PathVisualizer(
                                        source:   (risk['source']   ?? '').toString(),
                                        rel1Type: (risk['rel1Type'] ?? '').toString(),
                                        mediator: (risk['mediator'] ?? '').toString(),
                                        rel2Type: (risk['rel2Type'] ?? '').toString(),
                                        target:   (risk['target']   ?? '').toString(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _PathVisualizer extends StatelessWidget {
  final String source;
  final String rel1Type;
  final String mediator;
  final String rel2Type;
  final String target;

  const _PathVisualizer({
    required this.source,
    required this.rel1Type,
    required this.mediator,
    required this.rel2Type,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 8,
      children: [
        _NodeChip(label: source, scheme: scheme, isNode: true),
        _RelChip(label: rel1Type, scheme: scheme),
        _NodeChip(label: mediator, scheme: scheme, isNode: true),
        _RelChip(label: rel2Type, scheme: scheme),
        _NodeChip(label: target, scheme: scheme, isNode: true, isTarget: true),
      ],
    );
  }
}

class _NodeChip extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  final bool isNode;
  final bool isTarget;
  const _NodeChip({
    required this.label,
    required this.scheme,
    this.isNode = false,
    this.isTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = isTarget ? const Color(0xFFEF4444) : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _RelChip extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  const _RelChip({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_forward_rounded,
            size: 14, color: scheme.onSurface.withOpacity(0.35)),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.arrow_forward_rounded,
            size: 14, color: scheme.onSurface.withOpacity(0.35)),
      ],
    );
  }
}
