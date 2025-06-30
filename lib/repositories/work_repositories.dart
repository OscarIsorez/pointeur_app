import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointeur_app/bloc/backend_repository_internal_storage.dart';
import 'package:pointeur_app/models/work_session.dart';
import 'package:pointeur_app/models/work_settings.dart';

class WorkSessionRepository
    extends BackendRepositoryInternalStorage<WorkSession> {
  WorkSessionRepository()
    : super(
        storageKey: 'work_sessions',
        fromJson: WorkSession.fromJson,
        toJson: (session) => session.toJson(),
        getId: (session) => session.id,
      );

  /// Get today's work session or create a new one if it doesn't exist
  Future<WorkSession> getTodaySession() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final sessions = await fetchAll();
    final todaySession =
        sessions.where((session) {
          final sessionDate = DateTime(
            session.date.year,
            session.date.month,
            session.date.day,
          );
          return sessionDate.isAtSameMomentAs(todayDate);
        }).firstOrNull;

    if (todaySession != null) {
      return todaySession;
    }

    // Create a new session for today
    final newSession = WorkSession(date: todayDate);

    return await create(newSession);
  }

  /// Record arrival time for today
  Future<WorkSession> recordArrival() async {
    final session = await getTodaySession();
    final updatedSession = session.copyWith(arrivalTime: DateTime.now());
    return await update(updatedSession);
  }

  /// Record departure time for today
  Future<WorkSession> recordDeparture() async {
    final session = await getTodaySession();
    final updatedSession = session.copyWith(
      departureTime: DateTime.now(),
      isComplete: true,
    );
    return await update(updatedSession);
  }

  /// Start a break period
  Future<WorkSession> startBreak() async {
    final session = await getTodaySession();

    // Check if there's already an active break
    if (session.hasActiveBreak) {
      throw Exception('There is already an active break');
    }

    final newBreak = BreakPeriod(startTime: DateTime.now());

    final updatedBreaks = List<BreakPeriod>.from(session.breaks)..add(newBreak);
    final updatedSession = session.copyWith(breaks: updatedBreaks);

    return await update(updatedSession);
  }

  /// End the current break period
  Future<WorkSession> endBreak() async {
    final session = await getTodaySession();

    // Find the active break
    final activeBreakIndex = session.breaks.indexWhere(
      (break_) => !break_.isComplete,
    );
    if (activeBreakIndex == -1) {
      throw Exception('No active break found');
    }

    final updatedBreaks = List<BreakPeriod>.from(session.breaks);
    updatedBreaks[activeBreakIndex] = updatedBreaks[activeBreakIndex].copyWith(
      endTime: DateTime.now(),
      isComplete: true,
    );

    final updatedSession = session.copyWith(breaks: updatedBreaks);
    return await update(updatedSession);
  }

  /// Get work sessions for a specific date range
  Future<List<WorkSession>> getSessionsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sessions = await fetchAll();
    return sessions.where((session) {
      return session.date.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          session.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get work sessions for the current week
  Future<List<WorkSession>> getCurrentWeekSessions() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return await getSessionsInRange(startOfWeek, endOfWeek);
  }

  /// Get work sessions for the current month
  Future<List<WorkSession>> getCurrentMonthSessions() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return await getSessionsInRange(startOfMonth, endOfMonth);
  }

  /// Calculate total work time for a date range
  Future<Duration> getTotalWorkTime(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sessions = await getSessionsInRange(startDate, endDate);
    return sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.totalWorkTime,
    );
  }

  /// Calculate work time surplus/deficit for a date range
  Future<Duration> getWorkTimeSurplus(
    DateTime startDate,
    DateTime endDate,
    WorkSettings settings,
  ) async {
    final sessions = await getSessionsInRange(startDate, endDate);
    final totalWorked = sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.totalWorkTime,
    );

    final workingDays = sessions.length;
    final expectedWork = Duration(
      milliseconds: (settings.dailyWorkDuration.inMilliseconds * workingDays),
    );

    return totalWorked - expectedWork;
  }
}

class WorkSettingsRepository {
  static const String _settingsKey = 'work_settings';

  Future<WorkSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString == null) {
      // Return default settings
      return const WorkSettings();
    }

    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return WorkSettings.fromJson(jsonMap);
  }

  Future<WorkSettings> updateSettings(WorkSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
    return settings;
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}

// Extension to add firstOrNull method if not available
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
