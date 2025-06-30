class WorkSettings {
  final double dailyWorkHours;
  final Duration breakDuration;
  final bool enableNotifications;
  final String workStartTime; // Format: "HH:mm"
  final String workEndTime; // Format: "HH:mm"

  const WorkSettings({
    this.dailyWorkHours = 8.0,
    this.breakDuration = const Duration(minutes: 30),
    this.enableNotifications = true,
    this.workStartTime = "09:00",
    this.workEndTime = "17:00",
  });

  Duration get dailyWorkDuration => Duration(
    hours: dailyWorkHours.floor(),
    minutes: ((dailyWorkHours - dailyWorkHours.floor()) * 60).round(),
  );

  WorkSettings copyWith({
    double? dailyWorkHours,
    Duration? breakDuration,
    bool? enableNotifications,
    String? workStartTime,
    String? workEndTime,
  }) {
    return WorkSettings(
      dailyWorkHours: dailyWorkHours ?? this.dailyWorkHours,
      breakDuration: breakDuration ?? this.breakDuration,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyWorkHours': dailyWorkHours,
      'breakDurationMinutes': breakDuration.inMinutes,
      'enableNotifications': enableNotifications,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
    };
  }

  factory WorkSettings.fromJson(Map<String, dynamic> json) {
    return WorkSettings(
      dailyWorkHours: json['dailyWorkHours']?.toDouble() ?? 8.0,
      breakDuration: Duration(minutes: json['breakDurationMinutes'] ?? 30),
      enableNotifications: json['enableNotifications'] ?? true,
      workStartTime: json['workStartTime'] ?? "09:00",
      workEndTime: json['workEndTime'] ?? "17:00",
    );
  }

  @override
  String toString() {
    return 'WorkSettings(dailyWorkHours: $dailyWorkHours, breakDuration: $breakDuration, enableNotifications: $enableNotifications, workStartTime: $workStartTime, workEndTime: $workEndTime)';
  }
}
