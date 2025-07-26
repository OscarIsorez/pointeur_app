import 'package:equatable/equatable.dart';
import 'package:pointeur_app/models/work_session.dart';
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

  const WorkSessionLoadingState({this.lastKnownSession, this.lastKnownStatus});

  @override
  List<Object?> get props => [lastKnownSession, lastKnownStatus];
}

class WorkSessionLoadedState extends WorkSessionState {
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

class WorkSessionErrorState extends WorkSessionState {
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
