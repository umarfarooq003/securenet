// lib/messa/models/device_state.dart

import 'package:flutter/material.dart';

class DeviceState {
  final int id;
  final String name;
  final String deviceType;
  final String ip;
  final bool infected;
  final bool recovered;
  final bool resistant;
  final double securityLevel;
  final List<int> connections;

  const DeviceState({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.ip,
    required this.infected,
    required this.recovered,
    required this.resistant,
    required this.securityLevel,
    required this.connections,
  });

  factory DeviceState.fromJson(Map<String, dynamic> j) => DeviceState(
        id: j['id'] as int,
        name: j['name'] as String,
        deviceType: j['device_type'] as String,
        ip: j['ip'] as String,
        infected: j['infected'] as bool,
        recovered: j['recovered'] as bool,
        resistant: j['resistant'] as bool,
        securityLevel: (j['security_level'] as num).toDouble(),
        connections: List<int>.from(j['connections'] as List),
      );

  String get stateLabel {
    if (infected) return 'Infected';
    if (resistant) return 'Resistant';
    if (recovered) return 'Recovered';
    return 'Healthy';
  }

  Color get stateColor {
    if (infected) return const Color(0xFFEF4444);
    if (resistant) return const Color(0xFF3B82F6);
    if (recovered) return const Color(0xFF10B981);
    return const Color(0xFF8B5CF6);
  }

  IconData get stateIcon {
    if (infected) return Icons.bug_report_rounded;
    if (resistant) return Icons.shield_rounded;
    if (recovered) return Icons.healing_rounded;
    return Icons.check_circle_rounded;
  }

  IconData get deviceIcon {
    switch (deviceType) {
      case 'Endpoint':
        return Icons.laptop_rounded;
      case 'Router':
        return Icons.router_rounded;
      case 'Switch':
      case 'AggregationSwitch':
        return Icons.device_hub_rounded;
      case 'Firewall':
        return Icons.security_rounded;
      case 'Server':
        return Icons.dns_rounded;
      case 'AccessPoint':
        return Icons.wifi_rounded;
      case 'ISP':
        return Icons.public_rounded;
      default:
        return Icons.devices_rounded;
    }
  }
}
