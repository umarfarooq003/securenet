// lib/messa/models/step_result.dart

import 'device_state.dart';

class StepResult {
  final int step;
  final int totalDevices;
  final int infectedCount;
  final int recoveredCount;
  final int resistantCount;
  final int healthyCount;
  final double infectionRate;
  final List<DeviceState> devices;
  final List<dynamic> newInfections;
  final List<dynamic> recoveredDevices;
  final List<dynamic> newResistance;
  final List<dynamic> successfulDetections;

  const StepResult({
    required this.step,
    required this.totalDevices,
    required this.infectedCount,
    required this.recoveredCount,
    required this.resistantCount,
    required this.healthyCount,
    required this.infectionRate,
    required this.devices,
    required this.newInfections,
    required this.recoveredDevices,
    required this.newResistance,
    required this.successfulDetections,
  });

  factory StepResult.fromJson(Map<String, dynamic> j) => StepResult(
        step: j['step'] as int,
        totalDevices: j['total_devices'] as int,
        infectedCount: j['infected_count'] as int,
        recoveredCount: j['recovered_count'] as int,
        resistantCount: j['resistant_count'] as int,
        healthyCount: j['healthy_count'] as int,
        infectionRate: (j['infection_rate'] as num).toDouble(),
        devices: (j['devices'] as List)
            .map((d) => DeviceState.fromJson(d as Map<String, dynamic>))
            .toList(),
        newInfections: List.from(j['new_infections'] as List? ?? []),
        recoveredDevices: List.from(j['recovered_devices'] as List? ?? []),
        newResistance: List.from(j['new_resistance'] as List? ?? []),
        successfulDetections:
            List.from(j['successful_detections'] as List? ?? []),
      );

  /// Percentage 0–1 for progress bars
  double get infectedFraction =>
      totalDevices > 0 ? infectedCount / totalDevices : 0;
  double get healthyFraction =>
      totalDevices > 0 ? healthyCount / totalDevices : 0;
  double get recoveredFraction =>
      totalDevices > 0 ? recoveredCount / totalDevices : 0;
  double get resistantFraction =>
      totalDevices > 0 ? resistantCount / totalDevices : 0;
}
