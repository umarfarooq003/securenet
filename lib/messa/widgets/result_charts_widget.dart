// lib/messa/widgets/result_charts_widget.dart
//
// Post-simulation charts:
//   1. Pie chart  — final device-state distribution
//   2. Bar chart  — per device-type infection breakdown
//   3. Save CSV   — exports step-history to a CSV file

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simulation_provider.dart';

class ResultChartsWidget extends StatefulWidget {
  const ResultChartsWidget({super.key});

  @override
  State<ResultChartsWidget> createState() => _ResultChartsWidgetState();
}

class _ResultChartsWidgetState extends State<ResultChartsWidget> {
  bool _saving = false;
  String? _savedPath;

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<SimulationProvider>();
    final result = prov.result;
    final scheme = Theme.of(context).colorScheme;

    if (result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Pie chart ──────────────────────────────────────────────────────
        _ChartCard(
          icon: Icons.pie_chart_rounded,
          title: 'Final State Distribution',
          child: SizedBox(
            height: 220,
            child: Row(
              children: [
                // Pie
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      sections: [
                        _pieSection(result.infectedCount,  result.totalDevices,
                            const Color(0xFFEF4444), 'Inf'),
                        _pieSection(result.healthyCount,   result.totalDevices,
                            const Color(0xFF8B5CF6), 'Hlth'),
                        _pieSection(result.recoveredCount, result.totalDevices,
                            const Color(0xFF10B981), 'Rec'),
                        _pieSection(result.resistantCount, result.totalDevices,
                            const Color(0xFF3B82F6), 'Res'),
                      ],
                    ),
                  ),
                ),
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PieLegendRow(
                          const Color(0xFFEF4444), 'Infected',
                          result.infectedCount, result.totalDevices),
                      _PieLegendRow(
                          const Color(0xFF8B5CF6), 'Healthy',
                          result.healthyCount, result.totalDevices),
                      _PieLegendRow(
                          const Color(0xFF10B981), 'Recovered',
                          result.recoveredCount, result.totalDevices),
                      _PieLegendRow(
                          const Color(0xFF3B82F6), 'Resistant',
                          result.resistantCount, result.totalDevices),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Bar chart ──────────────────────────────────────────────────────
        _ChartCard(
          icon: Icons.bar_chart_rounded,
          title: 'Infection by Device Type',
          child: SizedBox(
            height: 220,
            child: _DeviceTypeBarChart(breakdown: prov.typeBreakdown),
          ),
        ),
        const SizedBox(height: 14),

        // ── Save CSV ───────────────────────────────────────────────────────
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.save_alt_rounded,
                        color: scheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Export Simulation Data',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _savedPath != null
                            ? 'Saved to:\n$_savedPath'
                            : '${prov.stepHistory.length} steps  •  '
                                '${result.totalDevices} devices',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.65),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              _savedPath != null
                                  ? Icons.check_rounded
                                  : Icons.download_rounded),
                      label: Text(_saving
                          ? 'Saving…'
                          : _savedPath != null
                              ? 'Saved!'
                              : 'Save CSV'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _savedPath != null
                            ? const Color(0xFF10B981)
                            : scheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (_saving || _savedPath != null)
                          ? null
                          : _exportCsv,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PieChartSectionData _pieSection(
      int count, int total, Color color, String label) {
    final pct = total > 0 ? (count / total * 100) : 0.0;
    return PieChartSectionData(
      value: count.toDouble(),
      color: color,
      radius: 60,
      title: count > 0 ? '${pct.toStringAsFixed(0)}%' : '',
      titleStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _saving = true);
    try {
      final path =
          await context.read<SimulationProvider>().exportCsv();
      setState(() {
        _saving    = false;
        _savedPath = path;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pie legend row
// ─────────────────────────────────────────────────────────────────────────────
class _PieLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _PieLegendRow(this.color, this.label, this.count, this.total);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          Text(
            '$count ($pct%)',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar chart — per device-type breakdown
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceTypeBarChart extends StatelessWidget {
  final Map<String, Map<String, int>> breakdown;

  const _DeviceTypeBarChart({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final types = breakdown.keys.toList();

    // Short labels
    String shortLabel(String t) {
      switch (t) {
        case 'Endpoint':          return 'EP';
        case 'AccessPoint':       return 'AP';
        case 'Switch':            return 'SW';
        case 'AggregationSwitch': return 'AS';
        case 'Router':            return 'RT';
        case 'Firewall':          return 'FW';
        case 'Server':            return 'SR';
        case 'ISP':               return 'ISP';
        default:                  return t.substring(0, 2).toUpperCase();
      }
    }

    final barGroups = types.asMap().entries.map((entry) {
      final i    = entry.key;
      final type = entry.value;
      final data = breakdown[type]!;
      return BarChartGroupData(
        x: i,
        groupVertically: false,
        barRods: [
          BarChartRodData(
            toY: (data['infected']!).toDouble(),
            color: const Color(0xFFEF4444),
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: (data['healthy']!).toDouble(),
            color: const Color(0xFF8B5CF6),
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: (data['recovered']!).toDouble(),
            color: const Color(0xFF10B981),
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: (data['resistant']!).toDouble(),
            color: const Color(0xFF3B82F6),
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
        barsSpace: 2,
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 16,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= types.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  shortLabel(types[i]),
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chart card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ChartCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: scheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
