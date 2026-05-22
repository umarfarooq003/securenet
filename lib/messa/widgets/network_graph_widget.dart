// lib/messa/widgets/network_graph_widget.dart
//
// Live network graph that shows device states as coloured nodes.
// Hierarchical layout: ISP → Router → Firewall → AggSwitch → Switch/Server
//                     → AccessPoint → Endpoint
//
// Pan & pinch-to-zoom via InteractiveViewer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_state.dart';
import '../providers/simulation_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────
class NetworkGraphWidget extends StatelessWidget {
  const NetworkGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<SimulationProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (prov.nodePositions.isEmpty || prov.result == null) {
      return const SizedBox.shrink();
    }

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
            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.account_tree_rounded,
                    color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Network Infection Map  —  Step ${prov.result!.step}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (prov.isRunning)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Legend ─────────────────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: const [
                _LegendDot(Color(0xFFEF4444), 'Infected'),
                _LegendDot(Color(0xFF8B5CF6), 'Healthy'),
                _LegendDot(Color(0xFF10B981), 'Recovered'),
                _LegendDot(Color(0xFF3B82F6), 'Resistant'),
              ],
            ),
            const SizedBox(height: 8),

            // ── Graph canvas ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 340,
                color: scheme.surfaceContainerHighest.withOpacity(0.4),
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(40),
                  minScale: 0.4,
                  maxScale: 8.0,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _NetworkPainter(
                        positions:    prov.nodePositions,
                        edges:        prov.topologyEdges,
                        deviceStates: prov.result!.devices,
                      ),
                      // Fixed inner canvas size — zoom/pan via InteractiveViewer
                      child: const SizedBox(width: 700, height: 600),
                    ),
                  ),
                ),
              ),
            ),

            // ── Hint ───────────────────────────────────────────────────────
            const SizedBox(height: 6),
            Text(
              'Pinch to zoom • Drag to pan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.45),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter
// ─────────────────────────────────────────────────────────────────────────────
class _NetworkPainter extends CustomPainter {
  final Map<int, Offset> positions; // normalised 0..1
  final List<dynamic> edges;
  final List<DeviceState> deviceStates;

  late final Map<int, DeviceState> _stateMap;

  _NetworkPainter({
    required this.positions,
    required this.edges,
    required this.deviceStates,
  }) {
    _stateMap = {for (final d in deviceStates) d.id: d};
  }

  static const _edgeColor = Color(0x22888888);

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = _edgeColor
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    // 1 — draw edges
    for (final edge in edges) {
      final srcId = edge['source'] as int?;
      final tgtId = edge['target'] as int?;
      if (srcId == null || tgtId == null) continue;
      final src = positions[srcId];
      final tgt = positions[tgtId];
      if (src == null || tgt == null) continue;

      canvas.drawLine(
        Offset(src.dx * size.width, src.dy * size.height),
        Offset(tgt.dx * size.width, tgt.dy * size.height),
        edgePaint,
      );
    }

    // 2 — draw nodes
    for (final entry in positions.entries) {
      final id    = entry.key;
      final pos   = entry.value;
      final state = _stateMap[id];

      final Color fill = state == null
          ? const Color(0xFF6B7280)
          : state.infected
              ? const Color(0xFFEF4444)
              : state.resistant
                  ? const Color(0xFF3B82F6)
                  : state.recovered
                      ? const Color(0xFF10B981)
                      : const Color(0xFF8B5CF6);

      final radius = _radius(state?.deviceType ?? 'Endpoint');
      final centre = Offset(pos.dx * size.width, pos.dy * size.height);

      // Glow for infected
      if (state?.infected == true && radius > 3) {
        canvas.drawCircle(
          centre,
          radius + 3,
          Paint()..color = const Color(0xFFEF4444).withOpacity(0.25),
        );
      }

      // Fill
      canvas.drawCircle(centre, radius, Paint()..color = fill);

      // Border for larger nodes
      if (radius >= 5) {
        canvas.drawCircle(
          centre,
          radius,
          Paint()
            ..color = Colors.white.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
    }
  }

  double _radius(String type) {
    switch (type) {
      case 'ISP':
        return 9;
      case 'Router':
      case 'Firewall':
        return 8;
      case 'AggregationSwitch':
        return 7;
      case 'Switch':
      case 'Server':
        return 6;
      case 'AccessPoint':
        return 5;
      default: // Endpoint
        return 3;
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter old) =>
      old.deviceStates != deviceStates ||
      old.positions != positions;
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend dot
// ─────────────────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    ]);
  }
}
