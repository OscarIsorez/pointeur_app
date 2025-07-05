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

  // Debug methods
  /// Debug: Print all work sessions in memory
  Future<void> debugPrintAllSessions() async {
    print('\n=== DEBUG: All Work Sessions ===');
    final sessions = await fetchAll();

    if (sessions.isEmpty) {
      print('No work sessions found in storage.');
      return;
    }

    print('Found ${sessions.length} work session(s):');
    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      print('\n--- Session ${i + 1} ---');
      print('ID: ${session.id}');
      print('Date: ${_formatDate(session.date)}');
      print(
        'Arrival: ${session.arrivalTime != null ? _formatTime(session.arrivalTime!) : 'Not set'}',
      );
      print(
        'Departure: ${session.departureTime != null ? _formatTime(session.departureTime!) : 'Not set'}',
      );
      print('Is Complete: ${session.isComplete}');
      print('Total Work Time: ${_formatDuration(session.totalWorkTime)}');
      print('Has Active Break: ${session.hasActiveBreak}');
      print('Number of Breaks: ${session.breaks.length}');
    }
    print('=== End Debug ===\n');
  }

  /// Debug: Print today's work session details
  Future<void> debugPrintTodaySession() async {
    print('\n=== DEBUG: Today\'s Work Session ===');
    try {
      final session = await getTodaySession();
      print('Session ID: ${session.id}');
      print('Date: ${_formatDate(session.date)}');
      print(
        'Arrival: ${session.arrivalTime != null ? _formatTime(session.arrivalTime!) : 'Not set'}',
      );
      print(
        'Departure: ${session.departureTime != null ? _formatTime(session.departureTime!) : 'Not set'}',
      );
      print('Is Complete: ${session.isComplete}');
      print('Total Work Time: ${_formatDuration(session.totalWorkTime)}');
      print('Has Active Break: ${session.hasActiveBreak}');
      print('Number of Breaks: ${session.breaks.length}');

      // Current status
      String status = 'Unknown';
      if (session.arrivalTime == null) {
        status = 'Not started';
      } else if (session.departureTime != null) {
        status = 'Finished';
      } else if (session.hasActiveBreak) {
        status = 'On break';
      } else {
        status = 'Working';
      }
      print('Current Status: $status');
    } catch (e) {
      print('Error getting today\'s session: $e');
    }
    print('=== End Debug ===\n');
  }

  // Helper methods for formatting
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Delete today's work session
  Future<void> deleteTodaySession() async {
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
      await delete(todaySession.id);
      print('🗑️ Deleted today\'s session (ID: ${todaySession.id})');
    } else {
      print('⚠️ No session found for today to delete');
    }
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

  // Debug methods
  /// Debug: Print current settings
  Future<void> debugPrintSettings() async {
    print('\n=== DEBUG: Work Settings ===');
    try {
      final settings = await getSettings();
      print('Daily Work Hours: ${settings.dailyWorkHours}');
      print('Break Duration: ${settings.breakDuration.inMinutes} minutes');
      print('Enable Notifications: ${settings.enableNotifications}');
      print('Work Start Time: ${settings.workStartTime}');
      print('Work End Time: ${settings.workEndTime}');
      print(
        'Daily Work Duration: ${settings.dailyWorkDuration.inHours}h ${settings.dailyWorkDuration.inMinutes.remainder(60)}m',
      );
    } catch (e) {
      print('Error getting settings: $e');
    }
    print('=== End Debug ===\n');
  }
}

// Extension to add firstOrNull method if not available
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
