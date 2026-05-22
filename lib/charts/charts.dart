import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/graphql_service.dart';
import '../widgets/shared_widgets.dart';

class NetworkCharts extends StatefulWidget {
  const NetworkCharts({super.key});
  @override
  State<NetworkCharts> createState() => _NetworkChartsState();
}

class _NetworkChartsState extends State<NetworkCharts> with SingleTickerProviderStateMixin {
  final GraphQLService _service = GraphQLService();
  Map<String, int> counts = {
    'Routers': 0, 'Switches': 0, 'Servers': 0, 'End Points': 0,
    'Suspected': 0, 'Infected': 0, 'Recovered': 0, 'Vulnerabilities': 0,
  };
  bool isLoading = true;
  String? error;
  int _touchedIndex = -1;
  late TabController _tabController;

  // Refined palette aligned with design system
  static const List<Color> _palette = [
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFF0EA5E9), // sky
    Color(0xFF14B8A6), // teal
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF10B981), // green
    Color(0xFFEC4899), // pink
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchCounts() async {
    if (mounted) setState(() { isLoading = true; error = null; });
    try {
      final nodes = await _service.fetchNodes();
      final tmp = Map<String, int>.from(counts.map((k, _) => MapEntry(k, 0)));
      for (final n in nodes) {
        final label      = ((n['nodeType'] ?? n['name'] ?? '') as dynamic).toString().toLowerCase();
        final status     = (n['status'] ?? '').toString().toLowerCase();
        final properties = (n['allProperties'] ?? '').toString().toLowerCase();
        if (label.contains('router'))   tmp['Routers'] = tmp['Routers']! + 1;
        else if (label.contains('switch')) tmp['Switches'] = tmp['Switches']! + 1;
        else if (label.contains('server')) tmp['Servers'] = tmp['Servers']! + 1;
        else if (label.contains('endpoint') || label.contains('device')) tmp['End Points'] = tmp['End Points']! + 1;
        if (status.contains('suspected') || properties.contains('suspected')) tmp['Suspected'] = tmp['Suspected']! + 1;
        if (status.contains('infected')  || properties.contains('infected'))  tmp['Infected']  = tmp['Infected']!  + 1;
        if (status.contains('recovered') || properties.contains('recovered')) tmp['Recovered'] = tmp['Recovered']! + 1;
        if (properties.contains('vulnerability')) tmp['Vulnerabilities'] = tmp['Vulnerabilities']! + 1;
      }
      if (mounted) setState(() { counts = Map.from(tmp); isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); isLoading = false; });
    }
  }

  List<PieChartSectionData> _pieData(List<MapEntry<String, int>> entries) {
    final total = entries.fold(0, (a, b) => a + b.value);
    if (total == 0) return [];
    return List.generate(entries.length, (i) {
      final e       = entries[i];
      final pct     = (e.value / total * 100);
      final touched = i == _touchedIndex;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: touched ? '${e.key}\n${pct.toStringAsFixed(1)}%' : '${pct.toStringAsFixed(0)}%',
        color: _palette[i % _palette.length],
        radius: touched ? 90 : 72,
        titleStyle: TextStyle(
          fontSize: touched ? 13 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    });
  }

  List<BarChartGroupData> _barData(List<MapEntry<String, int>> entries) {
    return List.generate(entries.length, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value.toDouble(),
              color: _palette[i % _palette.length],
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.15),
                color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
              ),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = counts.entries.where((e) => e.value > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: fetchCounts,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart_rounded), text: 'Distribution'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Comparison'),
          ],
        ),
      ),
      body: isLoading
          ? const LoadingOverlay(label: 'Loading analytics…')
          : error != null
              ? ErrorState(message: error!, onRetry: fetchCounts)
              : entries.isEmpty
                  ? const EmptyState(
                      icon: Icons.analytics_outlined,
                      title: 'No data available',
                      subtitle: 'No network data found to display charts.',
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPieTab(entries, scheme),
                        _buildBarTab(entries, scheme),
                      ],
                    ),
    );
  }

  // ── Pie chart tab ───────────────────────────────────────────────────────────
  Widget _buildPieTab(List<MapEntry<String, int>> entries, ColorScheme scheme) {
    final total = entries.fold(0, (a, b) => a + b.value);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Donut
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Network Distribution',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Total nodes: $total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withOpacity(0.5),
                          )),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sections: _pieData(entries),
                        centerSpaceRadius: 52,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend grid
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Legend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      final c = _palette[i % _palette.length];
                      return Row(
                        children: [
                          Container(width: 12, height: 12,
                              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(e.key,
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 4),
                          Text('${e.value}',
                              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w700)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart tab ───────────────────────────────────────────────────────────
  Widget _buildBarTab(List<MapEntry<String, int>> entries, ColorScheme scheme) {
    final maxY = (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.3).toDouble();
    final interval = (maxY / 5).ceilToDouble().clamp(1.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Node Count Comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Tap bars for details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.5),
                      )),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    barGroups: _barData(entries),
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: scheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: scheme.inverseSurface,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                          '${entries[gi].key}\n${rod.toY.toInt()}',
                          TextStyle(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: interval,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= entries.length) return const SizedBox();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                entries[idx].key.replaceAll(' ', '\n'),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: scheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
