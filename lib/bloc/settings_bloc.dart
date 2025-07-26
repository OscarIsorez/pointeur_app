import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/bloc/settings_events.dart';
import 'package:pointeur_app/bloc/settings_states.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final WorkTimeService _workTimeService;

  SettingsBloc({WorkTimeService? workTimeService})
    : _workTimeService = workTimeService ?? WorkTimeService(),
      super(SettingsInitialState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<ResetSettingsEvent>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoadingState());
    try {
      final settings = await _workTimeService.getSettings();
      emit(SettingsLoadedState(settings: settings));
    } catch (e) {
      emit(SettingsErrorState('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;

    // Show loading but preserve current settings to avoid UI flicker
    if (currentState is SettingsLoadedState) {
      emit(SettingsLoadingState(lastKnownSettings: currentState.settings));
    } else {
      emit(SettingsLoadingState());
    }

    try {
      final updatedSettings = await _workTimeService.updateSettings(
        event.settings,
      );
      emit(
        SettingsLoadedState(
          settings: updatedSettings,
          successMessage: 'Paramètres mis à jour avec succès!',
        ),
      );
    } catch (e) {
      final lastKnownSettings =
          currentState is SettingsLoadedState ? currentState.settings : null;
      emit(
        SettingsErrorState(
          'Échec de la mise à jour des paramètres: ${e.toString()}',
          lastKnownSettings: lastKnownSettings,
        ),
      );
    }
  }

  Future<void> _onResetSettings(
    ResetSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoadingState());
    try {
      const defaultSettings = WorkSettings(); // Uses default values
      final updatedSettings = await _workTimeService.updateSettings(
        defaultSettings,
      );
      emit(
        SettingsLoadedState(
          settings: updatedSettings,
          successMessage: 'Paramètres réinitialisés!',
        ),
      );
    } catch (e) {
      emit(
        SettingsErrorState(
          'Échec de la réinitialisation des paramètres: ${e.toString()}',
        ),
      );
    }
  }
}
