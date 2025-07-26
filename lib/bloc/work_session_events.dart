import 'package:equatable/equatable.dart';
import 'package:pointeur_app/models/work_session.dart';

abstract class WorkSessionEvent extends Equatable {
  const WorkSessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodaySessionEvent extends WorkSessionEvent {}

class RecordArrivalEvent extends WorkSessionEvent {}

class RecordDepartureEvent extends WorkSessionEvent {}

class StartBreakEvent extends WorkSessionEvent {}

class EndBreakEvent extends WorkSessionEvent {}

class UpdateSessionEvent extends WorkSessionEvent {
  final WorkSession session;

  const UpdateSessionEvent(this.session);

  @override
  List<Object?> get props => [session];
}

class RefreshWorkSessionEvent extends WorkSessionEvent {}
