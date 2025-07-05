import 'package:pointeur_app/repositories/work_repositories.dart';

/// Debug utility class for work session and settings debugging
class WorkDebugHelper {
  static final WorkSessionRepository _sessionRepo = WorkSessionRepository();
  static final WorkSettingsRepository _settingsRepo = WorkSettingsRepository();

  /// Print all debug information
  static Future<void> printAllDebugInfo() async {
    await _sessionRepo.debugPrintAllSessions();
    await _sessionRepo.debugPrintTodaySession();
    await _settingsRepo.debugPrintSettings();
  }

  /// Print only session information
  static Future<void> printSessionInfo() async {
    await _sessionRepo.debugPrintAllSessions();
    await _sessionRepo.debugPrintTodaySession();
  }

  /// Print only today's session
  static Future<void> printTodaySession() async {
    await _sessionRepo.debugPrintTodaySession();
  }

  /// Print only settings
  static Future<void> printSettings() async {
    await _settingsRepo.debugPrintSettings();
  }

  /// Print all sessions in storage
  static Future<void> printAllSessions() async {
    await _sessionRepo.debugPrintAllSessions();
  }

  /// Delete today's session
  static Future<void> deleteTodaySession() async {
    await _sessionRepo.deleteTodaySession();
  }
}
