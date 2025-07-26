import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/bloc/work_session_events.dart';
import 'package:pointeur_app/bloc/work_session_states.dart';

class WorkSessionBloc extends Bloc<WorkSessionEvent, WorkSessionState> {
  final WorkTimeService _workTimeService;

  WorkSessionBloc({WorkTimeService? workTimeService})
    : _workTimeService = workTimeService ?? WorkTimeService(),
      super(WorkSessionInitialState()) {
    on<LoadTodaySessionEvent>(_onLoadTodaySession);
    on<RecordArrivalEvent>(_onRecordArrival);
    on<RecordDepartureEvent>(_onRecordDeparture);
    on<StartBreakEvent>(_onStartBreak);
    on<EndBreakEvent>(_onEndBreak);
    on<UpdateSessionEvent>(_onUpdateSession);
    on<RefreshWorkSessionEvent>(_onRefreshWorkSession);
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
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.recordArrival();
      final status = await _workTimeService.getCurrentStatus();

      emit(
        WorkSessionLoadedState(
          todaySession: session,
          currentStatus: status,
          successMessage: 'Arrivée enregistrée avec succès!',
        ),
      );
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;

      emit(
        WorkSessionErrorState(
          'Échec de l\'enregistrement de l\'arrivée: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
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
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.recordDeparture();
      final status = await _workTimeService.getCurrentStatus();

      emit(
        WorkSessionLoadedState(
          todaySession: session,
          currentStatus: status,
          successMessage: 'Départ enregistré avec succès!',
        ),
      );
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;

      emit(
        WorkSessionErrorState(
          'Échec de l\'enregistrement du départ: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
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
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.startBreak();
      final status = await _workTimeService.getCurrentStatus();

      emit(
        WorkSessionLoadedState(
          todaySession: session,
          currentStatus: status,
          successMessage: 'Pause commencée!',
        ),
      );
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;

      emit(
        WorkSessionErrorState(
          'Échec du début de pause: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
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
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.endBreak();
      final status = await _workTimeService.getCurrentStatus();

      emit(
        WorkSessionLoadedState(
          todaySession: session,
          currentStatus: status,
          successMessage: 'Pause terminée!',
        ),
      );
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;

      emit(
        WorkSessionErrorState(
          'Échec de la fin de pause: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
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
        emit(
          WorkSessionLoadedState(
            todaySession: updatedSession,
            currentStatus: status,
            successMessage: 'Session mise à jour avec succès!',
          ),
        );
      } else {
        // If updating a past session, keep today's session and just show success
        final todaySession = await _workTimeService.getTodaySession();
        final status = await _workTimeService.getCurrentStatus();
        emit(
          WorkSessionLoadedState(
            todaySession: todaySession,
            currentStatus: status,
            successMessage: 'Session passée mise à jour avec succès!',
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

      emit(
        WorkSessionErrorState(
          'Échec de la mise à jour de session: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
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
        ),
      );
    } else {
      emit(WorkSessionLoadingState());
    }

    try {
      final session = await _workTimeService.getTodaySession();
      final status = await _workTimeService.getCurrentStatus();

      emit(
        WorkSessionLoadedState(todaySession: session, currentStatus: status),
      );
    } catch (e) {
      final lastSession =
          currentState is WorkSessionLoadedState
              ? currentState.todaySession
              : null;
      final lastStatus =
          currentState is WorkSessionLoadedState
              ? currentState.currentStatus
              : null;

      emit(
        WorkSessionErrorState(
          'Échec du rafraîchissement: ${e.toString()}',
          lastKnownSession: lastSession,
          lastKnownStatus: lastStatus,
        ),
      );
    }
  }
}
