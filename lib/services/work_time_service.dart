import 'package:pointeur_app/models/work_session.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/repositories/settings_repository.dart';
import 'package:pointeur_app/repositories/work_repositories.dart';

enum WorkStatus { notStarted, working, onBreak, finished }

class WorkTimeService {
  final WorkSessionRepository _sessionRepository;
  final WorkSettingsRepository _settingsRepository;

  WorkTimeService({
    WorkSessionRepository? sessionRepository,
    WorkSettingsRepository? settingsRepository,
  }) : _sessionRepository = sessionRepository ?? WorkSessionRepository(),
       _settingsRepository = settingsRepository ?? WorkSettingsRepository();

  /// Get current work status
  Future<WorkStatus> getCurrentStatus() async {
    try {
      final session = await _sessionRepository.getTodaySession();

      if (session.arrivalTime == null) {
        return WorkStatus.notStarted;
      }

      if (session.departureTime != null) {
        return WorkStatus.finished;
      }

      if (session.hasActiveBreak) {
        return WorkStatus.onBreak;
      }

      return WorkStatus.working;
    } catch (e) {
      return WorkStatus.notStarted;
    }
  }

  /// Record arrival
  Future<WorkSession> recordArrival() async {
    final status = await getCurrentStatus();
    if (status != WorkStatus.notStarted) {
      throw Exception('Cannot record arrival: work day already started');
    }
    return await _sessionRepository.recordArrival();
  }

  /// Record departure
  Future<WorkSession> recordDeparture() async {
    final status = await getCurrentStatus();
    if (status == WorkStatus.notStarted) {
      throw Exception('Cannot record departure: work day not started');
    }
    if (status == WorkStatus.finished) {
      throw Exception('Work day already finished');
    }

    // End any active break before departure
    if (status == WorkStatus.onBreak) {
      await _sessionRepository.endBreak();
    }

    return await _sessionRepository.recordDeparture();
  }

  /// Start break
  Future<WorkSession> startBreak() async {
    final status = await getCurrentStatus();
    if (status != WorkStatus.working) {
      throw Exception('Cannot start break: not currently working');
    }
    return await _sessionRepository.startBreak();
  }

  /// End break
  Future<WorkSession> endBreak() async {
    final status = await getCurrentStatus();
    if (status != WorkStatus.onBreak) {
      throw Exception('Cannot end break: not currently on break');
    }
    return await _sessionRepository.endBreak();
  }

  /// Get today's session
  Future<WorkSession> getTodaySession() async {
    return await _sessionRepository.getTodaySession();
  }

  /// Get session for a specific date
  Future<WorkSession> getSessionByDate(DateTime date) async {
    return await _sessionRepository.getSessionByDate(date);
  }

  /// Get work settings
  Future<WorkSettings> getSettings() async {
    return await _settingsRepository.getSettings();
  }

  /// Update work settings
  Future<WorkSettings> updateSettings(WorkSettings settings) async {
    return await _settingsRepository.updateSettings(settings);
  }

  /// Update a work session
  Future<WorkSession> updateSession(WorkSession session) async {
    return await _sessionRepository.update(session);
  }

  /// Get work data for charts (last 7 days)
  Future<List<WorkDayData>> getWeeklyWorkData() async {
    final sessions = await _sessionRepository.getCurrentWeekSessions();
    final settings = await getSettings();

    return sessions.map((session) {
      final date = session.date;
      final totalWork = session.totalWorkTime;
      final expectedWork = settings.dailyWorkDuration;
      final surplus = totalWork - expectedWork;

      return WorkDayData(
        date: date,
        totalWorkTime: totalWork,
        expectedWorkTime: expectedWork,
        surplus: surplus,
        totalBreakTime: session.totalBreakTime,
        isComplete: session.isComplete,
      );
    }).toList();
  }

  /// Get monthly work summary
  Future<WorkSummary> getMonthlyWorkSummary() async {
    final sessions = await _sessionRepository.getCurrentMonthSessions();
    final settings = await getSettings();

    // Only count completed sessions for consistency
    final completedSessions = sessions.where((s) => s.isComplete).toList();

    final totalWorked = completedSessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.totalWorkTime,
    );

    final totalBreaks = completedSessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.totalBreakTime,
    );

    final workingDays = completedSessions.length;
    final expectedTotal = Duration(
      milliseconds: settings.dailyWorkDuration.inMilliseconds * workingDays,
    );

    final surplus = totalWorked - expectedTotal;

    return WorkSummary(
      totalWorkTime: totalWorked,
      totalBreakTime: totalBreaks,
      expectedWorkTime: expectedTotal,
      surplus: surplus,
      workingDays: workingDays,
      averageWorkTime:
          workingDays > 0
              ? Duration(
                milliseconds: totalWorked.inMilliseconds ~/ workingDays,
              )
              : Duration.zero,
    );
  }

  /// Get all work data for charts (all available sessions)
  Future<List<WorkDayData>> getAllWorkData() async {
    final sessions = await _sessionRepository.fetchAll();
    final settings = await getSettings();

    return sessions.map((session) {
      final date = session.date;
      final totalWork = session.totalWorkTime;
      final expectedWork = settings.dailyWorkDuration;
      final surplus = totalWork - expectedWork;

      return WorkDayData(
        date: date,
        totalWorkTime: totalWork,
        expectedWorkTime: expectedWork,
        surplus: surplus,
        totalBreakTime: session.totalBreakTime,
        isComplete: session.isComplete,
      );
    }).toList();
  }

  /// Format duration to hours and minutes string
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if duration is positive surplus
  bool isPositiveSurplus(Duration surplus) {
    return surplus.inMilliseconds > 0;
  }
}

class WorkDayData {
  final DateTime date;
  final Duration totalWorkTime;
  final Duration expectedWorkTime;
  final Duration surplus;
  final Duration totalBreakTime;
  final bool isComplete;

  WorkDayData({
    required this.date,
    required this.totalWorkTime,
    required this.expectedWorkTime,
    required this.surplus,
    required this.totalBreakTime,
    required this.isComplete,
  });

  double get totalWorkHours => totalWorkTime.inMinutes / 60.0;
  double get expectedWorkHours => expectedWorkTime.inMinutes / 60.0;
  double get surplusHours => surplus.inMinutes / 60.0;
  double get totalBreakHours => totalBreakTime.inMinutes / 60.0;
}

class WorkSummary {
  final Duration totalWorkTime;
  final Duration totalBreakTime;
  final Duration expectedWorkTime;
  final Duration surplus;
  final int workingDays;
  final Duration averageWorkTime;

  WorkSummary({
    required this.totalWorkTime,
    required this.totalBreakTime,
    required this.expectedWorkTime,
    required this.surplus,
    required this.workingDays,
    required this.averageWorkTime,
  });

  double get totalWorkHours => totalWorkTime.inMinutes / 60.0;
  double get expectedWorkHours => expectedWorkTime.inMinutes / 60.0;
  double get surplusHours => surplus.inMinutes / 60.0;
  double get averageWorkHours => averageWorkTime.inMinutes / 60.0;
}
