import 'package:equatable/equatable.dart';
import 'package:pointeur_app/models/work_session.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/services/work_time_service.dart';

abstract class WorkSessionState extends Equatable {
  const WorkSessionState();

  @override
  List<Object?> get props => [];
}

class WorkSessionInitialState extends WorkSessionState {}

class WorkSessionLoadingState extends WorkSessionState {
  final WorkSession? lastKnownSession;
  final WorkStatus? lastKnownStatus;
  final WorkSettings? lastKnownSettings;
  final List<WorkDayData>? lastKnownWeeklyData;
  final List<WorkDayData>? lastKnownAllWorkData;
  final WorkSummary? lastKnownMonthlySummary;

  const WorkSessionLoadingState({
    this.lastKnownSession,
    this.lastKnownStatus,
    this.lastKnownSettings,
    this.lastKnownWeeklyData,
    this.lastKnownAllWorkData,
    this.lastKnownMonthlySummary,
  });

  @override
  List<Object?> get props => [
    lastKnownSession,
    lastKnownStatus,
    lastKnownSettings,
    lastKnownWeeklyData,
    lastKnownAllWorkData,
    lastKnownMonthlySummary,
  ];
}

class WorkSessionLoadedState extends WorkSessionState {
  final WorkSession todaySession;
  final WorkStatus currentStatus;
  final WorkSettings? settings;
  final List<WorkDayData>? weeklyData;
  final List<WorkDayData>? allWorkData;
  final WorkSummary? monthlySummary;
  final String? successMessage;

  const WorkSessionLoadedState({
    required this.todaySession,
    required this.currentStatus,
    this.settings,
    this.weeklyData,
    this.allWorkData,
    this.monthlySummary,
    this.successMessage,
  });

  WorkSessionLoadedState copyWith({
    WorkSession? todaySession,
    WorkStatus? currentStatus,
    WorkSettings? settings,
    List<WorkDayData>? weeklyData,
    List<WorkDayData>? allWorkData,
    WorkSummary? monthlySummary,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return WorkSessionLoadedState(
      todaySession: todaySession ?? this.todaySession,
      currentStatus: currentStatus ?? this.currentStatus,
      settings: settings ?? this.settings,
      weeklyData: weeklyData ?? this.weeklyData,
      allWorkData: allWorkData ?? this.allWorkData,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    todaySession,
    currentStatus,
    settings,
    weeklyData,
    allWorkData,
    monthlySummary,
    successMessage,
  ];
}

class WorkSessionErrorState extends WorkSessionState {
  final String message;
  final WorkSession? lastKnownSession;
  final WorkStatus? lastKnownStatus;
  final WorkSettings? lastKnownSettings;
  final List<WorkDayData>? lastKnownWeeklyData;
  final List<WorkDayData>? lastKnownAllWorkData;
  final WorkSummary? lastKnownMonthlySummary;

  const WorkSessionErrorState(
    this.message, {
    this.lastKnownSession,
    this.lastKnownStatus,
    this.lastKnownSettings,
    this.lastKnownWeeklyData,
    this.lastKnownAllWorkData,
    this.lastKnownMonthlySummary,
  });

  @override
  List<Object?> get props => [
    message,
    lastKnownSession,
    lastKnownStatus,
    lastKnownSettings,
    lastKnownWeeklyData,
    lastKnownAllWorkData,
    lastKnownMonthlySummary,
  ];
}
