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

class BackendLoadingState extends BackendState {}

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
  }) {
    return BackendLoadedState(
      todaySession: todaySession ?? this.todaySession,
      settings: settings ?? this.settings,
      currentStatus: currentStatus ?? this.currentStatus,
      weeklyData: weeklyData ?? this.weeklyData,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      successMessage: successMessage,
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

class BackendErrorState extends BackendState {
  final String message;

  const BackendErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
