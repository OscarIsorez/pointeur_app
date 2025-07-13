class WorkSettings {
  final double dailyWorkHours;
  final Duration breakDuration;
  final bool enableNotifications;

  const WorkSettings({
    this.dailyWorkHours = 8.0,
    this.breakDuration = const Duration(minutes: 30),
    this.enableNotifications = true,
  });

  Duration get dailyWorkDuration => Duration(
    hours: dailyWorkHours.floor(),
    minutes: ((dailyWorkHours - dailyWorkHours.floor()) * 60).round(),
  );

  WorkSettings copyWith({
    double? dailyWorkHours,
    Duration? breakDuration,
    bool? enableNotifications,
  }) {
    return WorkSettings(
      dailyWorkHours: dailyWorkHours ?? this.dailyWorkHours,
      breakDuration: breakDuration ?? this.breakDuration,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyWorkHours': dailyWorkHours,
      'breakDurationMinutes': breakDuration.inMinutes,
      'enableNotifications': enableNotifications,
    };
  }

  factory WorkSettings.fromJson(Map<String, dynamic> json) {
    return WorkSettings(
      dailyWorkHours: json['dailyWorkHours']?.toDouble() ?? 8.0,
      breakDuration: Duration(minutes: json['breakDurationMinutes'] ?? 30),
      enableNotifications: json['enableNotifications'] ?? true,
    );
  }

  @override
  String toString() {
    return 'WorkSettings(dailyWorkHours: $dailyWorkHours, breakDuration: $breakDuration, enableNotifications: $enableNotifications';
  }
}
