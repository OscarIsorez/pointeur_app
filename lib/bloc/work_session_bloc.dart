import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/bloc/work_session_events.dart';
import 'package:pointeur_app/bloc/work_session_states.dart';

class WorkSessionBloc extends Bloc<WorkSessionEvent, WorkSessionState> {
  final WorkTimeService _workTimeService;

  WorkSessionBloc({WorkTimeService? workTimeService})
    : _workTimeService = workTimeService ?? WorkTimeService(),
      super(WorkSessionInitialState()) {
    // Work session events
    on<LoadTodaySessionEvent>(_onLoadTodaySession);
    on<RecordArrivalEvent>(_onRecordArrival);
    on<RecordDepartureEvent>(_onRecordDeparture);
    on<StartBreakEvent>(_onStartBreak);
    on<EndBreakEvent>(_onEndBreak);
    on<UpdateSessionEvent>(_onUpdateSession);
    on<RefreshWorkSessionEvent>(_onRefreshWorkSession);

    // Settings events
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<UpdateWorkSessionSettingsEvent>(_onUpdateWorkSessionSettings);

    // Analytics/Data events
    on<LoadWeeklyDataEvent>(_onLoadWeeklyData);
    on<LoadMonthlySummaryEvent>(_onLoadMonthlySummary);
    on<RefreshAllDataEvent>(_onRefreshAllData);
  }

  Future<void> _onLoadTodaySession(
    LoadTodaySessionEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    emit(WorkSessionLoadingState());
    try {
      final session = await _workTimeService.getTodaySession();
      final status = await _workTimeService.getCurrentStatus();

      emit(
        WorkSessionLoadedState(todaySession: session, currentStatus: status),
      );
    } catch (e) {
      emit(
        WorkSessionErrorState(
          'Échec du chargement de la session: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRecordArrival(
    RecordArrivalEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    final currentState = state;

    // Preserve current data during loading
    if (currentState is WorkSessionLoadedState) {
      emit(
        WorkSessionLoadingState(
          lastKnownSession: currentState.todaySession,
          lastKnownStatus: currentState.currentStatus,
          lastKnownSettings: currentState.settings,
          lastKnownWeeklyData: currentState.weeklyData,
          lastKnownMonthlySummary: currentState.monthlySummary,
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.recordArrival();
      final status = await _workTimeService.getCurrentStatus();

      // Reload weekly data since today's data changed
      final weeklyData =
          currentState is WorkSessionLoadedState
              ? await _workTimeService.getWeeklyWorkData()
              : null;

      if (currentState is WorkSessionLoadedState) {
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            weeklyData: weeklyData,
            successMessage: 'Arrivée enregistrée avec succès!',
          ),
        );
      } else {
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            weeklyData: weeklyData,
            successMessage: 'Arrivée enregistrée avec succès!',
          ),
        );
      }
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;
      final lastSettings =
          currentState is WorkSessionLoadedState ? currentState.settings : null;
      final lastWeeklyData =
          currentState is WorkSessionLoadedState
              ? currentState.weeklyData
              : null;
      final lastMonthlySummary =
          currentState is WorkSessionLoadedState
              ? currentState.monthlySummary
              : null;

      emit(
        WorkSessionErrorState(
          'Échec de l\'enregistrement de l\'arrivée: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
          lastKnownSettings: lastSettings,
          lastKnownWeeklyData: lastWeeklyData,
          lastKnownMonthlySummary: lastMonthlySummary,
        ),
      );
    }
  }

  Future<void> _onRecordDeparture(
    RecordDepartureEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    final currentState = state;

    if (currentState is WorkSessionLoadedState) {
      emit(
        WorkSessionLoadingState(
          lastKnownSession: currentState.todaySession,
          lastKnownStatus: currentState.currentStatus,
          lastKnownSettings: currentState.settings,
          lastKnownWeeklyData: currentState.weeklyData,
          lastKnownMonthlySummary: currentState.monthlySummary,
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.recordDeparture();
      final status = await _workTimeService.getCurrentStatus();

      // Reload weekly data since today's data changed
      final weeklyData =
          currentState is WorkSessionLoadedState
              ? await _workTimeService.getWeeklyWorkData()
              : null;

      if (currentState is WorkSessionLoadedState) {
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            weeklyData: weeklyData,
            successMessage: 'Départ enregistré avec succès!',
          ),
        );
      } else {
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            weeklyData: weeklyData,
            successMessage: 'Départ enregistré avec succès!',
          ),
        );
      }
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;
      final lastSettings =
          currentState is WorkSessionLoadedState ? currentState.settings : null;
      final lastWeeklyData =
          currentState is WorkSessionLoadedState
              ? currentState.weeklyData
              : null;
      final lastMonthlySummary =
          currentState is WorkSessionLoadedState
              ? currentState.monthlySummary
              : null;

      emit(
        WorkSessionErrorState(
          'Échec de l\'enregistrement du départ: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
          lastKnownSettings: lastSettings,
          lastKnownWeeklyData: lastWeeklyData,
          lastKnownMonthlySummary: lastMonthlySummary,
        ),
      );
    }
  }

  Future<void> _onStartBreak(
    StartBreakEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    final currentState = state;

    if (currentState is WorkSessionLoadedState) {
      emit(
        WorkSessionLoadingState(
          lastKnownSession: currentState.todaySession,
          lastKnownStatus: currentState.currentStatus,
          lastKnownSettings: currentState.settings,
          lastKnownWeeklyData: currentState.weeklyData,
          lastKnownMonthlySummary: currentState.monthlySummary,
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.startBreak();
      final status = await _workTimeService.getCurrentStatus();

      if (currentState is WorkSessionLoadedState) {
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Pause commencée!',
          ),
        );
      } else {
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Pause commencée!',
          ),
        );
      }
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;
      final lastSettings =
          currentState is WorkSessionLoadedState ? currentState.settings : null;
      final lastWeeklyData =
          currentState is WorkSessionLoadedState
              ? currentState.weeklyData
              : null;
      final lastMonthlySummary =
          currentState is WorkSessionLoadedState
              ? currentState.monthlySummary
              : null;

      emit(
        WorkSessionErrorState(
          'Échec du début de pause: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
          lastKnownSettings: lastSettings,
          lastKnownWeeklyData: lastWeeklyData,
          lastKnownMonthlySummary: lastMonthlySummary,
        ),
      );
    }
  }

  Future<void> _onEndBreak(
    EndBreakEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    final currentState = state;

    if (currentState is WorkSessionLoadedState) {
      emit(
        WorkSessionLoadingState(
          lastKnownSession: currentState.todaySession,
          lastKnownStatus: currentState.currentStatus,
          lastKnownSettings: currentState.settings,
          lastKnownWeeklyData: currentState.weeklyData,
          lastKnownMonthlySummary: currentState.monthlySummary,
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.endBreak();
      final status = await _workTimeService.getCurrentStatus();

      if (currentState is WorkSessionLoadedState) {
        emit(
          currentState.copyWith(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Pause terminée!',
          ),
        );
      } else {
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            successMessage: 'Pause terminée!',
          ),
        );
      }
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;
      final lastSettings =
          currentState is WorkSessionLoadedState ? currentState.settings : null;
      final lastWeeklyData =
          currentState is WorkSessionLoadedState
              ? currentState.weeklyData
              : null;
      final lastMonthlySummary =
          currentState is WorkSessionLoadedState
              ? currentState.monthlySummary
              : null;

      emit(
        WorkSessionErrorState(
          'Échec de la fin de pause: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
          lastKnownSettings: lastSettings,
          lastKnownWeeklyData: lastWeeklyData,
          lastKnownMonthlySummary: lastMonthlySummary,
        ),
      );
    }
  }

  Future<void> _onUpdateSession(
    UpdateSessionEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    final currentState = state;

    if (currentState is WorkSessionLoadedState) {
      emit(
        WorkSessionLoadingState(
          lastKnownSession: currentState.todaySession,
          lastKnownStatus: currentState.currentStatus,
          lastKnownSettings: currentState.settings,
          lastKnownWeeklyData: currentState.weeklyData,
          lastKnownMonthlySummary: currentState.monthlySummary,
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final updatedSession = await _workTimeService.updateSession(
        event.session,
      );

      // Check if the updated session is for today
      final today = DateTime.now();
      final isToday =
          updatedSession.date.year == today.year &&
          updatedSession.date.month == today.month &&
          updatedSession.date.day == today.day;

      if (isToday) {
        // If updating today's session, update the state with the new session
        final status = await _workTimeService.getCurrentStatus();
        // Also reload weekly data since today's data changed
        final weeklyData =
            currentState is WorkSessionLoadedState
                ? await _workTimeService.getWeeklyWorkData()
                : null;

        if (currentState is WorkSessionLoadedState) {
          emit(
            currentState.copyWith(
              todaySession: updatedSession,
              currentStatus: status,
              weeklyData: weeklyData,
              successMessage: 'Session mise à jour avec succès!',
            ),
          );
        } else {
          emit(
            WorkSessionLoadedState(
              todaySession: updatedSession,
              currentStatus: status,
              weeklyData: weeklyData,
              successMessage: 'Session mise à jour avec succès!',
            ),
          );
        }
      } else {
        // If updating a past session, keep today's session and reload weekly data
        final todaySession = await _workTimeService.getTodaySession();
        final status = await _workTimeService.getCurrentStatus();
        final weeklyData = await _workTimeService.getWeeklyWorkData();

        if (currentState is WorkSessionLoadedState) {
          emit(
            currentState.copyWith(
              todaySession: todaySession,
              currentStatus: status,
              weeklyData: weeklyData,
              successMessage: 'Session passée mise à jour avec succès!',
            ),
          );
        } else {
          emit(
            WorkSessionLoadedState(
              todaySession: todaySession,
              currentStatus: status,
              weeklyData: weeklyData,
              successMessage: 'Session passée mise à jour avec succès!',
            ),
          );
        }
      }
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;
      final lastSettings =
          currentState is WorkSessionLoadedState ? currentState.settings : null;
      final lastWeeklyData =
          currentState is WorkSessionLoadedState
              ? currentState.weeklyData
              : null;
      final lastMonthlySummary =
          currentState is WorkSessionLoadedState
              ? currentState.monthlySummary
              : null;

      emit(
        WorkSessionErrorState(
          'Échec de la mise à jour de session: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
          lastKnownSettings: lastSettings,
          lastKnownWeeklyData: lastWeeklyData,
          lastKnownMonthlySummary: lastMonthlySummary,
        ),
      );
    }
  }

  Future<void> _onRefreshWorkSession(
    RefreshWorkSessionEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    // Use current data during refresh
    final currentState = state;
    if (currentState is WorkSessionLoadedState) {
      emit(
        WorkSessionLoadingState(
          lastKnownSession: currentState.todaySession,
          lastKnownStatus: currentState.currentStatus,
          lastKnownSettings: currentState.settings,
          lastKnownWeeklyData: currentState.weeklyData,
          lastKnownMonthlySummary: currentState.monthlySummary,
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.getTodaySession();
      final status = await _workTimeService.getCurrentStatus();

      if (currentState is WorkSessionLoadedState) {
        emit(
          currentState.copyWith(todaySession: session, currentStatus: status),
        );
      } else {
        emit(
          WorkSessionLoadedState(todaySession: session, currentStatus: status),
        );
      }
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;
      final lastSettings =
          currentState is WorkSessionLoadedState ? currentState.settings : null;
      final lastWeeklyData =
          currentState is WorkSessionLoadedState
              ? currentState.weeklyData
              : null;
      final lastMonthlySummary =
          currentState is WorkSessionLoadedState
              ? currentState.monthlySummary
              : null;

      emit(
        WorkSessionErrorState(
          'Échec du rafraîchissement: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
          lastKnownSettings: lastSettings,
          lastKnownWeeklyData: lastWeeklyData,
          lastKnownMonthlySummary: lastMonthlySummary,
        ),
      );
    }
  }

  // Settings event handlers
  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    try {
      final settings = await _workTimeService.getSettings();

      if (state is WorkSessionLoadedState) {
        final currentState = state as WorkSessionLoadedState;
        emit(currentState.copyWith(settings: settings));
      } else {
        // If we don't have a loaded state yet, also load the basic session data
        final session = await _workTimeService.getTodaySession();
        final status = await _workTimeService.getCurrentStatus();
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            settings: settings,
          ),
        );
      }
    } catch (e) {
      final currentState = state;
      if (currentState is WorkSessionLoadedState) {
        emit(
          WorkSessionErrorState(
            'Échec du chargement des paramètres: ${e.toString()}',
            lastKnownSession: currentState.todaySession,
            lastKnownStatus: currentState.currentStatus,
            lastKnownSettings: currentState.settings,
            lastKnownWeeklyData: currentState.weeklyData,
            lastKnownMonthlySummary: currentState.monthlySummary,
          ),
        );
      } else {
        emit(
          WorkSessionErrorState(
            'Échec du chargement des paramètres: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    try {
      final settings = await _workTimeService.updateSettings(event.settings);

      if (state is WorkSessionLoadedState) {
        final currentState = state as WorkSessionLoadedState;
        emit(
          currentState.copyWith(
            settings: settings,
            successMessage: 'Paramètres mis à jour avec succès!',
          ),
        );
      } else {
        // If we don't have a loaded state yet, also load the basic session data
        final session = await _workTimeService.getTodaySession();
        final status = await _workTimeService.getCurrentStatus();
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            settings: settings,
            successMessage: 'Paramètres mis à jour avec succès!',
          ),
        );
      }
    } catch (e) {
      final currentState = state;
      if (currentState is WorkSessionLoadedState) {
        emit(
          WorkSessionErrorState(
            'Échec de la mise à jour des paramètres: ${e.toString()}',
            lastKnownSession: currentState.todaySession,
            lastKnownStatus: currentState.currentStatus,
            lastKnownSettings: currentState.settings,
            lastKnownWeeklyData: currentState.weeklyData,
            lastKnownMonthlySummary: currentState.monthlySummary,
          ),
        );
      } else {
        emit(
          WorkSessionErrorState(
            'Échec de la mise à jour des paramètres: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onUpdateWorkSessionSettings(
    UpdateWorkSessionSettingsEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    if (state is WorkSessionLoadedState) {
      final currentState = state as WorkSessionLoadedState;
      emit(currentState.copyWith(settings: event.settings));
    }
  }

  // Analytics/Data event handlers
  Future<void> _onLoadWeeklyData(
    LoadWeeklyDataEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    try {
      final weeklyData = await _workTimeService.getWeeklyWorkData();

      if (state is WorkSessionLoadedState) {
        final currentState = state as WorkSessionLoadedState;
        emit(currentState.copyWith(weeklyData: weeklyData));
      } else {
        // If we don't have a loaded state yet, also load the basic session data
        final session = await _workTimeService.getTodaySession();
        final status = await _workTimeService.getCurrentStatus();
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            weeklyData: weeklyData,
          ),
        );
      }
    } catch (e) {
      final currentState = state;
      if (currentState is WorkSessionLoadedState) {
        emit(
          WorkSessionErrorState(
            'Échec du chargement des données hebdomadaires: ${e.toString()}',
            lastKnownSession: currentState.todaySession,
            lastKnownStatus: currentState.currentStatus,
            lastKnownSettings: currentState.settings,
            lastKnownWeeklyData: currentState.weeklyData,
            lastKnownMonthlySummary: currentState.monthlySummary,
          ),
        );
      } else {
        emit(
          WorkSessionErrorState(
            'Échec du chargement des données hebdomadaires: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onLoadMonthlySummary(
    LoadMonthlySummaryEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    try {
      final monthlySummary = await _workTimeService.getMonthlyWorkSummary();

      if (state is WorkSessionLoadedState) {
        final currentState = state as WorkSessionLoadedState;
        emit(currentState.copyWith(monthlySummary: monthlySummary));
      } else {
        // If we don't have a loaded state yet, also load the basic session data
        final session = await _workTimeService.getTodaySession();
        final status = await _workTimeService.getCurrentStatus();
        emit(
          WorkSessionLoadedState(
            todaySession: session,
            currentStatus: status,
            monthlySummary: monthlySummary,
          ),
        );
      }
    } catch (e) {
      final currentState = state;
      if (currentState is WorkSessionLoadedState) {
        emit(
          WorkSessionErrorState(
            'Échec du chargement du résumé mensuel: ${e.toString()}',
            lastKnownSession: currentState.todaySession,
            lastKnownStatus: currentState.currentStatus,
            lastKnownSettings: currentState.settings,
            lastKnownWeeklyData: currentState.weeklyData,
            lastKnownMonthlySummary: currentState.monthlySummary,
          ),
        );
      } else {
        emit(
          WorkSessionErrorState(
            'Échec du chargement du résumé mensuel: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onRefreshAllData(
    RefreshAllDataEvent event,
    Emitter<WorkSessionState> emit,
  ) async {
    emit(WorkSessionLoadingState());
    try {
      final session = await _workTimeService.getTodaySession();
      final status = await _workTimeService.getCurrentStatus();
      final settings = await _workTimeService.getSettings();
      final weeklyData = await _workTimeService.getWeeklyWorkData();
      final monthlySummary = await _workTimeService.getMonthlyWorkSummary();

      emit(
        WorkSessionLoadedState(
          todaySession: session,
          currentStatus: status,
          settings: settings,
          weeklyData: weeklyData,
          monthlySummary: monthlySummary,
        ),
      );
    } catch (e) {
      emit(
        WorkSessionErrorState(
          'Échec du rafraîchissement des données: ${e.toString()}',
        ),
      );
    }
  }
}
