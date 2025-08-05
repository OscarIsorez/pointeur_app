import 'package:equatable/equatable.dart';
import 'package:pointeur_app/models/work_session.dart';
import 'package:pointeur_app/models/work_settings.dart';

abstract class WorkSessionEvent extends Equatable {
  const WorkSessionEvent();

  @override
  List<Object?> get props => [];
}

// Work session events
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

// Settings events
class LoadSettingsEvent extends WorkSessionEvent {}

class UpdateSettingsEvent extends WorkSessionEvent {
  final WorkSettings settings;

  const UpdateSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateWorkSessionSettingsEvent extends WorkSessionEvent {
  final WorkSettings settings;

  const UpdateWorkSessionSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

// Analytics/Data events
class LoadWeeklyDataEvent extends WorkSessionEvent {}

class LoadMonthlySummaryEvent extends WorkSessionEvent {}

class RefreshAllDataEvent extends WorkSessionEvent {}
