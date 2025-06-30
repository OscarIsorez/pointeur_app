import 'package:uuid/uuid.dart';

enum WorkEventType { arrival, departure, breakStart, breakEnd }

class WorkEvent {
  final String id;
  final DateTime timestamp;
  final WorkEventType type;
  final String? note;

  WorkEvent({
    String? id,
    required this.timestamp,
    required this.type,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'note': note,
    };
  }

  factory WorkEvent.fromJson(Map<String, dynamic> json) {
    return WorkEvent(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      type: WorkEventType.values.firstWhere((e) => e.name == json['type']),
      note: json['note'],
    );
  }

  @override
  String toString() {
    return 'WorkEvent(id: $id, timestamp: $timestamp, type: $type, note: $note)';
  }
}

class WorkSession {
  final String id;
  final DateTime date;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final List<BreakPeriod> breaks;
  final bool isComplete;

  WorkSession({
    String? id,
    required this.date,
    this.arrivalTime,
    this.departureTime,
    List<BreakPeriod>? breaks,
    this.isComplete = false,
  }) : id = id ?? const Uuid().v4(),
       breaks = breaks ?? [];

  Duration get totalWorkTime {
    if (arrivalTime == null) return Duration.zero;

    final endTime = departureTime ?? DateTime.now();
    final totalTime = endTime.difference(arrivalTime!);
    final totalBreakTime = breaks.fold<Duration>(
      Duration.zero,
      (sum, breakPeriod) => sum + breakPeriod.duration,
    );

    return totalTime - totalBreakTime;
  }

  Duration get totalBreakTime {
    return breaks.fold<Duration>(
      Duration.zero,
      (sum, breakPeriod) => sum + breakPeriod.duration,
    );
  }

  bool get hasActiveBreak {
    return breaks.any((breakPeriod) => !breakPeriod.isComplete);
  }

  WorkSession copyWith({
    String? id,
    DateTime? date,
    DateTime? arrivalTime,
    DateTime? departureTime,
    List<BreakPeriod>? breaks,
    bool? isComplete,
  }) {
    return WorkSession(
      id: id ?? this.id,
      date: date ?? this.date,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      breaks: breaks ?? this.breaks,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'arrivalTime': arrivalTime?.toIso8601String(),
      'departureTime': departureTime?.toIso8601String(),
      'breaks': breaks.map((b) => b.toJson()).toList(),
      'isComplete': isComplete,
    };
  }

  factory WorkSession.fromJson(Map<String, dynamic> json) {
    return WorkSession(
      id: json['id'],
      date: DateTime.parse(json['date']),
      arrivalTime:
          json['arrivalTime'] != null
              ? DateTime.parse(json['arrivalTime'])
              : null,
      departureTime:
          json['departureTime'] != null
              ? DateTime.parse(json['departureTime'])
              : null,
      breaks:
          (json['breaks'] as List<dynamic>?)
              ?.map((b) => BreakPeriod.fromJson(b))
              .toList() ??
          [],
      isComplete: json['isComplete'] ?? false,
    );
  }
}

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
