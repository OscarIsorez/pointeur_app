import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/utils/debug_helper.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<BackendBloc>().add(LoadTodaySessionEvent());
  }

  @override
  Widget build(BuildContext context) {
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
                    // Debug button - remove in production
                    IconButton(
                      onPressed: () => _showDebugInfo(),
                      icon: const Icon(Icons.bug_report, color: Colors.white),
                      tooltip: 'Debug Info',
                    ),
                    // Delete today's session button - remove in production
                    IconButton(
                      onPressed: () => _deleteTodaySession(),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      tooltip: 'Delete Today\'s Session',
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
                                  Text(
                                    'Temps travaillé: ${WorkTimeService().formatDuration(session.totalWorkTime)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
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
  void _deleteTodaySession() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer la session de travail d\'aujourd\'hui ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (kDebugMode) {
        print('\n🗑️ Delete Today\'s Session Requested from UI');
      }
      await WorkDebugHelper.deleteTodaySession();

      // Refresh the data after deletion
      if (mounted) {
        context.read<BackendBloc>().add(LoadTodaySessionEvent());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session d\'aujourd\'hui supprimée'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
