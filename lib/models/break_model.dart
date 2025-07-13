import 'package:uuid/uuid.dart';

class BreakPeriod {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isComplete;

  BreakPeriod({
    String? id,
    required this.startTime,
    this.endTime,
    this.isComplete = false,
  }) : id = id ?? const Uuid().v4();

  Duration get duration {
    if (!isComplete || endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  BreakPeriod copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    bool? isComplete,
  }) {
    return BreakPeriod(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isComplete': isComplete,
    };
  }

  factory BreakPeriod.fromJson(Map<String, dynamic> json) {
    return BreakPeriod(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isComplete: json['isComplete'] ?? false,
    );
  }
}
