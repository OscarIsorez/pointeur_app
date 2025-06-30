import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';

class BackendBloc extends Bloc<BackendEvent, BackendState> {
  final WorkTimeService _workTimeService;

  BackendBloc({WorkTimeService? workTimeService})
    : _workTimeService = workTimeService ?? WorkTimeService(),
      super(BackendInitialState()) {
    // Work tracking events
    on<LoadTodaySessionEvent>(_onLoadTodaySession);
    on<RecordArrivalEvent>(_onRecordArrival);
    on<RecordDepartureEvent>(_onRecordDeparture);
    on<StartBreakEvent>(_onStartBreak);
    on<EndBreakEvent>(_onEndBreak);

    // Settings events
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);

    // Data loading events
    on<LoadWeeklyDataEvent>(_onLoadWeeklyData);
    on<LoadMonthlySummaryEvent>(_onLoadMonthlySummary);
    on<RefreshAllDataEvent>(_onRefreshAllData);
  }

  Future<void> _onLoadTodaySession(
    LoadTodaySessionEvent event,
    Emitter<BackendState> emit,
  ) async {
    emit(BackendLoadingState());
    try {
      final session = await _workTimeService.getTodaySession();
      final status = await _workTimeService.getCurrentStatus();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(
          currentState.copyWith(todaySession: session, currentStatus: status),
        );
      } else {
        emit(BackendLoadedState(todaySession: session, currentStatus: status));
      }
    } catch (e) {
      emit(
        BackendErrorState('Failed to load today\'s session: ${e.toString()}'),
      );
    }
  }

  Future<void> _onRecordArrival(
    RecordArrivalEvent event,
    Emitter<BackendState> emit,
  ) async {
    emit(BackendLoadingState());
    try {
      final session = await _workTimeService.recordArrival();
      final status = await _workTimeService.getCurrentStatus();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Arrival recorded successfully!',
          ),
        );
      } else {
        emit(
          BackendLoadedState(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Arrival recorded successfully!',
          ),
        );
      }
    } catch (e) {
      emit(BackendErrorState('Failed to record arrival: ${e.toString()}'));
    }
  }

  Future<void> _onRecordDeparture(
    RecordDepartureEvent event,
    Emitter<BackendState> emit,
  ) async {
    emit(BackendLoadingState());
    try {
      final session = await _workTimeService.recordDeparture();
      final status = await _workTimeService.getCurrentStatus();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Departure recorded successfully!',
          ),
        );
      } else {
        emit(
          BackendLoadedState(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Departure recorded successfully!',
          ),
        );
      }
    } catch (e) {
      emit(BackendErrorState('Failed to record departure: ${e.toString()}'));
    }
  }

  Future<void> _onStartBreak(
    StartBreakEvent event,
    Emitter<BackendState> emit,
  ) async {
    emit(BackendLoadingState());
    try {
      final session = await _workTimeService.startBreak();
      final status = await _workTimeService.getCurrentStatus();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Break started!',
          ),
        );
      } else {
        emit(
          BackendLoadedState(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Break started!',
          ),
        );
      }
    } catch (e) {
      emit(BackendErrorState('Failed to start break: ${e.toString()}'));
    }
  }

  Future<void> _onEndBreak(
    EndBreakEvent event,
    Emitter<BackendState> emit,
  ) async {
    emit(BackendLoadingState());
    try {
      final session = await _workTimeService.endBreak();
      final status = await _workTimeService.getCurrentStatus();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Break ended!',
          ),
        );
      } else {
        emit(
          BackendLoadedState(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Break ended!',
          ),
        );
      }
    } catch (e) {
      emit(BackendErrorState('Failed to end break: ${e.toString()}'));
    }
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<BackendState> emit,
  ) async {
    try {
      final settings = await _workTimeService.getSettings();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(currentState.copyWith(settings: settings));
      } else {
        emit(BackendLoadedState(settings: settings));
      }
    } catch (e) {
      emit(BackendErrorState('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<BackendState> emit,
  ) async {
    emit(BackendLoadingState());
    try {
      final settings = await _workTimeService.updateSettings(event.settings);

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(
          currentState.copyWith(
            settings: settings,
            successMessage: 'Settings updated successfully!',
          ),
        );
      } else {
        emit(
          BackendLoadedState(
            settings: settings,
            successMessage: 'Settings updated successfully!',
          ),
        );
      }
    } catch (e) {
      emit(BackendErrorState('Failed to update settings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadWeeklyData(
    LoadWeeklyDataEvent event,
    Emitter<BackendState> emit,
  ) async {
    try {
      final weeklyData = await _workTimeService.getWeeklyWorkData();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(currentState.copyWith(weeklyData: weeklyData));
      } else {
        emit(BackendLoadedState(weeklyData: weeklyData));
      }
    } catch (e) {
      emit(BackendErrorState('Failed to load weekly data: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMonthlySummary(
    LoadMonthlySummaryEvent event,
    Emitter<BackendState> emit,
  ) async {
    try {
      final monthlySummary = await _workTimeService.getMonthlyWorkSummary();

      if (state is BackendLoadedState) {
        final currentState = state as BackendLoadedState;
        emit(currentState.copyWith(monthlySummary: monthlySummary));
      } else {
        emit(BackendLoadedState(monthlySummary: monthlySummary));
      }
    } catch (e) {
      emit(
        BackendErrorState('Failed to load monthly summary: ${e.toString()}'),
      );
    }
  }

  Future<void> _onRefreshAllData(
    RefreshAllDataEvent event,
    Emitter<BackendState> emit,
  ) async {
    emit(BackendLoadingState());
    try {
      final session = await _workTimeService.getTodaySession();
      final status = await _workTimeService.getCurrentStatus();
      final settings = await _workTimeService.getSettings();
      final weeklyData = await _workTimeService.getWeeklyWorkData();
      final monthlySummary = await _workTimeService.getMonthlyWorkSummary();

      emit(
        BackendLoadedState(
          todaySession: session,
          currentStatus: status,
          settings: settings,
          weeklyData: weeklyData,
          monthlySummary: monthlySummary,
        ),
      );
    } catch (e) {
      emit(BackendErrorState('Failed to refresh data: ${e.toString()}'));
    }
  }
}
