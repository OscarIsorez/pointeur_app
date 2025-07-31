// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/UI/screens/main_screen.dart';
import 'package:pointeur_app/bloc/settings_bloc.dart';
import 'package:pointeur_app/bloc/work_session_bloc.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TimeTrackerApp());
}

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SettingsBloc()),
        BlocProvider(create: (context) => WorkSessionBloc()),
      ],
      child: MaterialApp(
        title: 'Time Tracker',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.system,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
