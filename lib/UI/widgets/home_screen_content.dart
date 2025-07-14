import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/utils/debug_helper.dart';
import 'package:pointeur_app/UI/widgets/edit_session_dialog.dart';
import 'package:pointeur_app/models/work_session.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDataIfNeeded();
  }

  void _loadDataIfNeeded() {
    final currentState = context.read<BackendBloc>().state;

    // Load data if we're in initial or error state, or if we're missing specific data
    bool needsToLoad = false;

    if (currentState is BackendInitialState ||
        currentState is BackendErrorState) {
      needsToLoad = true;
    } else if (currentState is BackendLoadedState) {
      // Check if we have the data we need for this screen
      if (currentState.todaySession == null) {
        needsToLoad = true;
      }
    }

    if (needsToLoad) {
      context.read<BackendBloc>().add(LoadTodaySessionEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryTeal, AppColors.primaryTealDark],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header with app logo/title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 32, color: Colors.white),
                    const SizedBox(width: 16),
                    Text(
                      'Pointeur',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Edit session button - show when there's a session
                    BlocBuilder<BackendBloc, BackendState>(
                      builder: (context, state) {
                        if (state is BackendLoadedState &&
                            state.todaySession != null) {
                          return IconButton(
                            onPressed:
                                () =>
                                    _showEditSessionDialog(state.todaySession!),
                            icon: const Icon(Icons.edit, color: Colors.white),
                            tooltip: 'Edit Session',
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    // Debug button - remove in production
                    IconButton(
                      onPressed: () => _showDebugInfo(),
                      icon: const Icon(Icons.bug_report, color: Colors.white),
                      tooltip: 'Debug Info',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Main content
              Expanded(
                child: BlocConsumer<BackendBloc, BackendState>(
                  listener: (context, state) {
                    if (state is BackendErrorState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is BackendLoadedState &&
                        state.successMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.successMessage!),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is BackendLoadingState) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    } else if (state is BackendErrorState) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<BackendBloc>().add(
                                  LoadTodaySessionEvent(),
                                );
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is BackendLoadedState) {
                      final session = state.todaySession;
                      final isWorking =
                          session?.arrivalTime != null &&
                          session?.departureTime == null;
                      final isOnBreak = session?.hasActiveBreak ?? false;

                      return Column(
                        children: [
                          // Status card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  isWorking
                                      ? (isOnBreak ? Icons.coffee : Icons.work)
                                      : Icons.home,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isWorking
                                      ? (isOnBreak ? 'En pause' : 'Au travail')
                                      : 'Hors service',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (session != null) ...[
                                  // Show arrival and departure times in a more organized way
                                  if (session.arrivalTime != null ||
                                      session.departureTime != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          if (session.arrivalTime != null) ...[
                                            Column(
                                              children: [
                                                Icon(
                                                  Icons.login,
                                                  color: Colors.green,
                                                  size: 16,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatTime(
                                                    session.arrivalTime!,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  'Arrivée',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],

                                          if (session.departureTime !=
                                              null) ...[
                                            Column(
                                              children: [
                                                Icon(
                                                  Icons.logout,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatTime(
                                                    session.departureTime!,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  'Départ',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Show current break start time if on break
                                  if (isOnBreak &&
                                      session.breaks.isNotEmpty) ...[
                                    Builder(
                                      builder: (context) {
                                        final currentBreak =
                                            session.breaks.last;
                                        if (!currentBreak.isComplete) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.coffee,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  children: [
                                                    Text(
                                                      'Pause depuis ${_formatTime(currentBreak.startTime)}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      '(${_formatElapsedTime(currentBreak.duration)})',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  Text(
                                    'Temps travaillé: ${WorkTimeService().formatDuration(session.totalWorkTime)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pauses: ${session.breaks.length}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Aucune session aujourd\'hui',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action buttons
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isWorking) ...[
                                  _buildActionButton(
                                    context,
                                    'Arrivée',
                                    Icons.login,
                                    () {
                                      context.read<BackendBloc>().add(
                                        RecordArrivalEvent(),
                                      );
                                    },
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildActionButton(
                                          context,
                                          isOnBreak ? 'Fin de pause' : 'Pause',
                                          isOnBreak
                                              ? Icons.play_arrow
                                              : Icons.coffee,
                                          () {
                                            if (isOnBreak) {
                                              context.read<BackendBloc>().add(
                                                EndBreakEvent(),
                                              );
                                            } else {
                                              context.read<BackendBloc>().add(
                                                StartBreakEvent(),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildActionButton(
                                          context,
                                          'Départ',
                                          Icons.logout,
                                          () {
                                            context.read<BackendBloc>().add(
                                              RecordDepartureEvent(),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Format time to display hours and minutes (e.g., "09:30")
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format duration for elapsed time display (e.g., "1h 23min")
  String _formatElapsedTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  // Show edit session dialog
  void _showEditSessionDialog(WorkSession session) {
    showDialog(
      context: context,
      builder:
          (context) => EditSessionDialog(
            session: session,
            onSave: (updatedSession) {
              context.read<BackendBloc>().add(
                UpdateSessionEvent(updatedSession),
              );
            },
          ),
    );
  }

  // Debug method - remove in production
  void _showDebugInfo() async {
    if (kDebugMode) {
      print('\n🐛 Debug Info Requested from UI');
    }
    await WorkDebugHelper.printAllDebugInfo();

    // Also show a snackbar to confirm
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug info printed to console'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Delete today's session method - remove in production
}
