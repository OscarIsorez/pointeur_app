import 'package:equatable/equatable.dart';
import 'package:pointeur_app/models/work_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitialState extends SettingsState {}

class SettingsLoadingState extends SettingsState {
  final WorkSettings? lastKnownSettings;

  const SettingsLoadingState({this.lastKnownSettings});

  @override
  List<Object?> get props => [lastKnownSettings];
}

class SettingsLoadedState extends SettingsState {
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

class SettingsErrorState extends SettingsState {
  final String message;
  final WorkSettings? lastKnownSettings;

  const SettingsErrorState(this.message, {this.lastKnownSettings});

  @override
  List<Object?> get props => [message, lastKnownSettings];
}
