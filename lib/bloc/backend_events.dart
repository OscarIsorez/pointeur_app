import 'package:equatable/equatable.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/models/work_session.dart';

abstract class BackendEvent extends Equatable {
  const BackendEvent();

  @override
  List<Object?> get props => [];
}

// Work tracking events
class LoadTodaySessionEvent extends BackendEvent {}

class RecordArrivalEvent extends BackendEvent {}

class RecordDepartureEvent extends BackendEvent {}

class StartBreakEvent extends BackendEvent {}

class EndBreakEvent extends BackendEvent {}

class UpdateSessionEvent extends BackendEvent {
  final WorkSession session;

  const UpdateSessionEvent(this.session);

  @override
  List<Object?> get props => [session];
}

// Settings events
class LoadSettingsEvent extends BackendEvent {}

class UpdateSettingsEvent extends BackendEvent {
  final WorkSettings settings;

  const UpdateSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

// Data loading events
class LoadWeeklyDataEvent extends BackendEvent {}

class LoadMonthlySummaryEvent extends BackendEvent {}

class RefreshAllDataEvent extends BackendEvent {}
