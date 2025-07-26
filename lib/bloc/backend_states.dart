import 'package:equatable/equatable.dart';
import 'package:pointeur_app/models/work_session.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/services/work_time_service.dart';

abstract class BackendState extends Equatable {
  const BackendState();

  @override
  List<Object?> get props => [];
}

class BackendInitialState extends BackendState {}

class BackendLoadingState extends BackendState {
  final String? loadingMessage;

  const BackendLoadingState({this.loadingMessage});

  @override
  List<Object?> get props => [loadingMessage];
}

class BackendLoadedState extends BackendState {
  final WorkSession? todaySession;
  final WorkSettings? settings;
  final WorkStatus? currentStatus;
  final List<WorkDayData>? weeklyData;
  final WorkSummary? monthlySummary;
  final String? successMessage;

  const BackendLoadedState({
    this.todaySession,
    this.settings,
    this.currentStatus,
    this.weeklyData,
    this.monthlySummary,
    this.successMessage,
  });

  BackendLoadedState copyWith({
    WorkSession? todaySession,
    WorkSettings? settings,
    WorkStatus? currentStatus,
    List<WorkDayData>? weeklyData,
    WorkSummary? monthlySummary,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return BackendLoadedState(
      todaySession: todaySession ?? this.todaySession,
      settings: settings ?? this.settings,
      currentStatus: currentStatus ?? this.currentStatus,
      weeklyData: weeklyData ?? this.weeklyData,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    todaySession,
    settings,
    currentStatus,
    weeklyData,
    monthlySummary,
    successMessage,
  ];
}

// Specific state for settings operations
class SettingsLoadingState extends BackendState {}

class SettingsLoadedState extends BackendState {
  final WorkSettings settings;
  final String? successMessage;

  const SettingsLoadedState({required this.settings, this.successMessage});

  SettingsLoadedState copyWith({
    WorkSettings? settings,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return SettingsLoadedState(
      settings: settings ?? this.settings,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [settings, successMessage];
}

class SettingsErrorState extends BackendState {
  final String message;
  final WorkSettings? lastKnownSettings;

  const SettingsErrorState(this.message, {this.lastKnownSettings});

  @override
  List<Object?> get props => [message, lastKnownSettings];
}

// Specific state for work session operations
class WorkSessionLoadingState extends BackendState {}

class WorkSessionLoadedState extends BackendState {
  final WorkSession todaySession;
  final WorkStatus currentStatus;
  final String? successMessage;

  const WorkSessionLoadedState({
    required this.todaySession,
    required this.currentStatus,
    this.successMessage,
  });

  WorkSessionLoadedState copyWith({
    WorkSession? todaySession,
    WorkStatus? currentStatus,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return WorkSessionLoadedState(
      todaySession: todaySession ?? this.todaySession,
      currentStatus: currentStatus ?? this.currentStatus,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [todaySession, currentStatus, successMessage];
}

class WorkSessionErrorState extends BackendState {
  final String message;
  final WorkSession? lastKnownSession;
  final WorkStatus? lastKnownStatus;

  const WorkSessionErrorState(
    this.message, {
    this.lastKnownSession,
    this.lastKnownStatus,
  });

  @override
  List<Object?> get props => [message, lastKnownSession, lastKnownStatus];
}

// Specific state for analytics/reports
class AnalyticsLoadingState extends BackendState {}

class AnalyticsLoadedState extends BackendState {
  final List<WorkDayData>? weeklyData;
  final WorkSummary? monthlySummary;

  const AnalyticsLoadedState({this.weeklyData, this.monthlySummary});

  AnalyticsLoadedState copyWith({
    List<WorkDayData>? weeklyData,
    WorkSummary? monthlySummary,
  }) {
    return AnalyticsLoadedState(
      weeklyData: weeklyData ?? this.weeklyData,
      monthlySummary: monthlySummary ?? this.monthlySummary,
    );
  }

  @override
  List<Object?> get props => [weeklyData, monthlySummary];
}

class AnalyticsErrorState extends BackendState {
  final String message;

  const AnalyticsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class BackendErrorState extends BackendState {
  final String message;

  const BackendErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
