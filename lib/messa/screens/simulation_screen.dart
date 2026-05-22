// lib/messa/screens/simulation_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device_state.dart';
import '../providers/simulation_provider.dart';
import '../widgets/result_charts_widget.dart';
export '../providers/simulation_provider.dart' show SimStatus, ConnStatus;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point – wraps everything in the Provider
// ─────────────────────────────────────────────────────────────────────────────
class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SimulationProvider(),
      child: const _SimulationView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────
class _SimulationView extends StatelessWidget {
  const _SimulationView();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SimulationProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.biotech_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Infection Simulator'),
          ],
        ),
        actions: [
          if (prov.status != SimStatus.idle)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset',
              onPressed: () => context.read<SimulationProvider>().reset(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Server Connection ──────────────────────────────────────────
            _ServerPanel(),
            const SizedBox(height: 12),

            // ── Config Panel ───────────────────────────────────────────────
            _ConfigPanel(),
            const SizedBox(height: 16),

            // ── Action Buttons ─────────────────────────────────────────────
            _ActionButtons(),
            const SizedBox(height: 16),

            // ── Error banner ───────────────────────────────────────────────
            if (prov.errorMessage.isNotEmpty) _ErrorBanner(prov.errorMessage),

            // ── Stats + Line chart ──────────────────────────────────────
            if (prov.hasResult) ...[
              _StatsRow(),
              const SizedBox(height: 16),
              _ProgressBars(),
              const SizedBox(height: 16),
              _InfectionChart(),
              const SizedBox(height: 16),
            ],

            // ── Result charts + CSV (only after done) ───────────────────
            if (prov.isDone) ...[
              const ResultChartsWidget(),
              const SizedBox(height: 16),
            ],

            // ── Device list ─────────────────────────────────────────────
            if (prov.hasResult) ...[_DeviceList(), const SizedBox(height: 24)],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server connection panel
// ─────────────────────────────────────────────────────────────────────────────
class _ServerPanel extends StatefulWidget {
  @override
  State<_ServerPanel> createState() => _ServerPanelState();
}

class _ServerPanelState extends State<_ServerPanel> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: context.read<SimulationProvider>().serverUrl,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SimulationProvider>();
    final scheme = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (prov.connStatus) {
      case ConnStatus.ok:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Connected';
        break;
      case ConnStatus.failed:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error_rounded;
        statusLabel = 'Unreachable';
        break;
      case ConnStatus.checking:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.sync_rounded;
        statusLabel = 'Checking…';
        break;
      default:
        statusColor = scheme.onSurface.withOpacity(0.4);
        statusIcon = Icons.circle_outlined;
        statusLabel = 'Not tested';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              prov.connStatus == ConnStatus.ok
                  ? const Color(0xFF10B981).withOpacity(0.4)
                  : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(Icons.cable_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Backend Server',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      prov.connStatus == ConnStatus.checking
                          ? SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: statusColor,
                            ),
                          )
                          : Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // URL field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'https://messaapi.vercel.app',
                      prefixIcon: const Icon(Icons.dns_rounded, size: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (v) {
                      context.read<SimulationProvider>().updateServerUrl(v);
                      context.read<SimulationProvider>().testConnection();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed:
                      prov.connStatus == ConnStatus.checking
                          ? null
                          : () {
                            context.read<SimulationProvider>().updateServerUrl(
                              _ctrl.text,
                            );
                            context.read<SimulationProvider>().testConnection();
                          },
                  child: const Text('Test', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Config sliders
// ─────────────────────────────────────────────────────────────────────────────
class _ConfigPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SimulationProvider>();
    final cfg = prov.config;
    final scheme = Theme.of(context).colorScheme;
    final locked = prov.isRunning || prov.status == SimStatus.done;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Parameters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Slider(
              label: 'Infection Probability',
              value: cfg.infectionProbability,
              min: 0.1,
              max: 1.0,
              displayPct: true,
              locked: locked,
              onChanged:
                  (v) => context.read<SimulationProvider>().updateConfig(
                    cfg.copyWith(infectionProbability: v),
                  ),
            ),
            _Slider(
              label: 'Recovery Chance',
              value: cfg.recoveryChance,
              min: 0.0,
              max: 1.0,
              displayPct: true,
              locked: locked,
              onChanged:
                  (v) => context.read<SimulationProvider>().updateConfig(
                    cfg.copyWith(recoveryChance: v),
                  ),
            ),
            _Slider(
              label: 'Virus Spread Chance',
              value: cfg.virusSpreadChance,
              min: 0.0,
              max: 1.0,
              displayPct: true,
              locked: locked,
              onChanged:
                  (v) => context.read<SimulationProvider>().updateConfig(
                    cfg.copyWith(virusSpreadChance: v),
                  ),
            ),
            _Slider(
              label: 'Gain Resistance Chance',
              value: cfg.gainResistanceChance,
              min: 0.01,
              max: 1.0,
              displayPct: true,
              locked: locked,
              onChanged:
                  (v) => context.read<SimulationProvider>().updateConfig(
                    cfg.copyWith(gainResistanceChance: v),
                  ),
            ),
            _Slider(
              label: 'Virus Check Frequency',
              value: cfg.virusCheckFrequency,
              min: 0.0,
              max: 0.5,
              displayPct: true,
              locked: locked,
              onChanged:
                  (v) => context.read<SimulationProvider>().updateConfig(
                    cfg.copyWith(virusCheckFrequency: v),
                  ),
            ),
            _Slider(
              label: 'Initial Outbreak Size',
              value: cfg.initialOutbreakSize.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              displayPct: false,
              locked: locked,
              onChanged:
                  (v) => context.read<SimulationProvider>().updateConfig(
                    cfg.copyWith(initialOutbreakSize: v.round()),
                  ),
            ),
            _Slider(
              label: 'Simulation Speed',
              value: cfg.simulationSpeed,
              min: 0.1,
              max: 10.0,
              displayPct: false,
              valueSuffix: 'x',
              locked: locked,
              onChanged:
                  (v) => context.read<SimulationProvider>().updateConfig(
                    cfg.copyWith(simulationSpeed: v),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final bool displayPct;
  final bool locked;
  final String valueSuffix;
  final ValueChanged<double> onChanged;

  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayPct,
    required this.locked,
    required this.onChanged,
    this.divisions,
    this.valueSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display =
        displayPct
            ? '${(value * 100).round()}%'
            : '${value.toStringAsFixed(value >= 10 ? 0 : 1)}$valueSuffix';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: locked ? null : onChanged,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              display,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons — Run & Reset (Step Once removed)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SimulationProvider>();
    final status = prov.status;

    final bool isIdle = status == SimStatus.idle;
    final bool isLoading = status == SimStatus.loading;
    final bool isRunning = status == SimStatus.running;
    final bool isDone = status == SimStatus.done;
    final bool isError = status == SimStatus.error;

    // Label & icon for the primary button
    final String runLabel =
        isLoading
            ? 'Setting up…'
            : isRunning
            ? 'Running… Step ${prov.result?.step ?? 0}'
            : isDone
            ? 'Run Again'
            : 'Run Simulation';

    return Column(
      children: [
        // ── Progress bar (visible while running) ────────────────────────────
        if (isRunning && prov.result != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: prov.result!.infectedFraction,
              minHeight: 6,
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFEF4444)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Infected: ${prov.result!.infectedCount} / ${prov.result!.totalDevices}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${prov.result!.infectionRate.toStringAsFixed(1)}% rate',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // ── Done badge ──────────────────────────────────────────────────────
        if (isDone) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Simulation complete — ${prov.result?.step ?? 0} steps',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Main buttons ────────────────────────────────────────────────────
        Row(
          children: [
            // Run / Stop button
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                icon:
                    isLoading || isRunning
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Icon(
                          isDone
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                        ),
                label: Text(
                  isRunning ? 'Stop' : runLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isRunning
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    isLoading
                        ? null
                        : isRunning
                        ? () =>
                            context.read<SimulationProvider>().stopSimulation()
                        : () =>
                            context.read<SimulationProvider>().runSimulation(),
              ),
            ),
            const SizedBox(width: 12),
            // Reset button
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: const Color(0xFF8B5CF6),
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (isIdle && !isError && prov.result == null)
                        ? null
                        : () => context.read<SimulationProvider>().reset(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4 stat cards
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.watch<SimulationProvider>().result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Step ${r.step} — Live Stats',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                '${r.infectedCount}',
                'Infected',
                const Color(0xFFEF4444),
                Icons.bug_report_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatChip(
                '${r.healthyCount}',
                'Healthy',
                const Color(0xFF8B5CF6),
                Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatChip(
                '${r.recoveredCount}',
                'Recovered',
                const Color(0xFF10B981),
                Icons.healing_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatChip(
                '${r.resistantCount}',
                'Resistant',
                const Color(0xFF3B82F6),
                Icons.shield_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatChip(this.value, this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress bars
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressBars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.watch<SimulationProvider>().result!;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Infection Rate: ${r.infectionRate.toStringAsFixed(1)}%',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _Bar('Infected', r.infectedFraction, const Color(0xFFEF4444)),
            _Bar('Healthy', r.healthyFraction, const Color(0xFF8B5CF6)),
            _Bar('Recovered', r.recoveredFraction, const Color(0xFF10B981)),
            _Bar('Resistant', r.resistantFraction, const Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double fraction;
  final Color color;
  const _Bar(this.label, this.fraction, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(fraction * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line chart
// ─────────────────────────────────────────────────────────────────────────────
class _InfectionChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SimulationProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (prov.stepHistory.length < 2) return const SizedBox.shrink();

    LineChartBarData line(List<int> data, Color c) {
      return LineChartBarData(
        spots: List.generate(
          data.length,
          (i) => FlSpot(prov.stepHistory[i].toDouble(), data[i].toDouble()),
        ),
        isCurved: true,
        color: c,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: c.withOpacity(0.08)),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Infection Progression',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine:
                        (_) => FlLine(
                          color: scheme.outlineVariant,
                          strokeWidth: 0.5,
                        ),
                    getDrawingVerticalLine:
                        (_) => FlLine(
                          color: scheme.outlineVariant,
                          strokeWidth: 0.5,
                        ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget:
                            (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 9),
                            ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget:
                            (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 9),
                            ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    line(prov.infectedHistory, const Color(0xFFEF4444)),
                    line(prov.healthyHistory, const Color(0xFF8B5CF6)),
                    line(prov.recoveredHistory, const Color(0xFF10B981)),
                    line(prov.resistantHistory, const Color(0xFF3B82F6)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Wrap(
              spacing: 16,
              children: const [
                _Legend(Color(0xFFEF4444), 'Infected'),
                _Legend(Color(0xFF8B5CF6), 'Healthy'),
                _Legend(Color(0xFF10B981), 'Recovered'),
                _Legend(Color(0xFF3B82F6), 'Resistant'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device list
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceList extends StatefulWidget {
  @override
  State<_DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<_DeviceList> {
  String _filter = 'All';
  static const _filters = [
    'All',
    'Infected',
    'Healthy',
    'Recovered',
    'Resistant',
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SimulationProvider>();
    final scheme = Theme.of(context).colorScheme;
    final all = prov.result!.devices;

    final List<DeviceState> shown =
        _filter == 'All'
            ? all
            : all.where((d) => d.stateLabel == _filter).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.devices_rounded, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Devices (${shown.length}/${all.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = _filter == f;
                  return FilterChip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Device tiles
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shown.length > 50 ? 50 : shown.length,
              separatorBuilder:
                  (_, __) => Divider(height: 1, color: scheme.outlineVariant),
              itemBuilder: (_, i) => _DeviceTile(shown[i]),
            ),

            if (shown.length > 50)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '… and ${shown.length - 50} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceState d;
  const _DeviceTile(this.d);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: d.stateColor.withOpacity(0.12),
        child: Icon(d.deviceIcon, size: 16, color: d.stateColor),
      ),
      title: Text(
        d.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${d.deviceType}  •  ${d.ip}',
        style: TextStyle(
          fontSize: 11,
          color: scheme.onSurface.withOpacity(0.55),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: d.stateColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: d.stateColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(d.stateIcon, size: 12, color: d.stateColor),
            const SizedBox(width: 4),
            Text(
              d.stateLabel,
              style: TextStyle(
                fontSize: 11,
                color: d.stateColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
