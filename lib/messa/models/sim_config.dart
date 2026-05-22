// lib/messa/models/sim_config.dart

class SimConfig {
  final double simulationSpeed;
  final double infectionProbability;
  final double recoveryChance;
  final double virusSpreadChance;
  final int initialOutbreakSize;
  final double virusCheckFrequency;
  final double gainResistanceChance;

  const SimConfig({
    this.simulationSpeed = 1.0,
    this.infectionProbability = 0.7,
    this.recoveryChance = 0.1,
    this.virusSpreadChance = 1.0,
    this.initialOutbreakSize = 1,
    this.virusCheckFrequency = 0.05,
    this.gainResistanceChance = 0.5,
  });

  SimConfig copyWith({
    double? simulationSpeed,
    double? infectionProbability,
    double? recoveryChance,
    double? virusSpreadChance,
    int? initialOutbreakSize,
    double? virusCheckFrequency,
    double? gainResistanceChance,
  }) {
    return SimConfig(
      simulationSpeed: simulationSpeed ?? this.simulationSpeed,
      infectionProbability: infectionProbability ?? this.infectionProbability,
      recoveryChance: recoveryChance ?? this.recoveryChance,
      virusSpreadChance: virusSpreadChance ?? this.virusSpreadChance,
      initialOutbreakSize: initialOutbreakSize ?? this.initialOutbreakSize,
      virusCheckFrequency: virusCheckFrequency ?? this.virusCheckFrequency,
      gainResistanceChance: gainResistanceChance ?? this.gainResistanceChance,
    );
  }

  Map<String, dynamic> toJson() => {
    'simulation_speed': simulationSpeed,
    'infection_probability': infectionProbability,
    'recovery_chance': recoveryChance,
    'virus_spread_chance': virusSpreadChance,
    'initial_outbreak_size': initialOutbreakSize,
    'virus_check_frequency': virusCheckFrequency,
    'gain_resistance_chance': gainResistanceChance,
  };
}
