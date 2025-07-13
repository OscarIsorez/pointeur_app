import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (kDebugMode) {
      print('\n=== DEBUG: Work Settings ===');
      try {
        final settings = await getSettings();
        print('Daily Work Hours: ${settings.dailyWorkHours}');
        print('Break Duration: ${settings.breakDuration.inMinutes} minutes');
        print('Enable Notifications: ${settings.enableNotifications}');
        print(
          'Daily Work Duration: ${settings.dailyWorkDuration.inHours}h ${settings.dailyWorkDuration.inMinutes.remainder(60)}m',
        );
      } catch (e) {
        print('Error getting settings: $e');
      }
      print('=== End Debug ===\n');
    }
  }
}

// Extension to add firstOrNull method if not available
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
