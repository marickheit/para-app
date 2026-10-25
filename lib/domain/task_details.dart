enum EnergyLevel { low, medium, high }

extension EnergyLabel on EnergyLevel {
  String get label => switch (this) {
    EnergyLevel.low => 'Niedrig',
    EnergyLevel.medium => 'Mittel',
    EnergyLevel.high => 'Hoch',
  };
}

const taskDurationPresets = [5, 15, 30, 60, 120];
const contextColors = [
  0xff4b799e,
  0xffa76559,
  0xff65845d,
  0xff8c6c9c,
  0xff9a7b3e,
  0xff4c8b89,
];

class TaskContext {
  const TaskContext({
    required this.id,
    required this.name,
    required this.color,
    this.active = true,
    this.position = 0,
  });
  final String id;
  final String name;
  final int color;
  final bool active;
  final int position;
}

class TaskFilter {
  const TaskFilter({
    this.contextIds = const [],
    this.allContexts = false,
    this.maxMinutes,
    this.maxEnergy,
    this.includeUnspecified = true,
  });
  final List<String> contextIds;
  final bool allContexts;
  final int? maxMinutes;
  final EnergyLevel? maxEnergy;
  final bool includeUnspecified;
  bool get active =>
      contextIds.isNotEmpty || maxMinutes != null || maxEnergy != null;

  bool matches({
    required List<String> contexts,
    required int? minutes,
    required EnergyLevel? energy,
  }) {
    if (contextIds.isNotEmpty) {
      if (contexts.isEmpty) {
        if (!includeUnspecified) return false;
      } else if (allContexts
          ? !contextIds.every(contexts.contains)
          : !contextIds.any(contexts.contains)) {
        return false;
      }
    }
    if (maxMinutes != null &&
        (minutes == null ? !includeUnspecified : minutes > maxMinutes!)) {
      return false;
    }
    if (maxEnergy != null &&
        (energy == null
            ? !includeUnspecified
            : energy.index > maxEnergy!.index)) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'contexts': contextIds,
    'all': allContexts,
    'minutes': maxMinutes,
    'energy': maxEnergy?.name,
    'unspecified': includeUnspecified,
  };
  factory TaskFilter.fromJson(Map<String, dynamic> json) => TaskFilter(
    contextIds: (json['contexts'] as List? ?? []).cast<String>(),
    allContexts: json['all'] == true,
    maxMinutes: json['minutes'] as int?,
    maxEnergy: EnergyLevel.values
        .where((e) => e.name == json['energy'])
        .firstOrNull,
    includeUnspecified: json['unspecified'] != false,
  );
}
