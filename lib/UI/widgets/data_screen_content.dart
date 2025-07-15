import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/UI/widgets/weekly_work_chart.dart';
import 'dart:async';

class DataScreenContent extends StatefulWidget {
  const DataScreenContent({super.key});

  @override
  State<DataScreenContent> createState() => _DataScreenContentState();
}

class _DataScreenContentState extends State<DataScreenContent>
    with AutomaticKeepAliveClientMixin {
  Timer? _workTimeTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDataIfNeeded();
  }

  @override
  void dispose() {
    _workTimeTimer?.cancel();
    super.dispose();
  }

  void _startWorkTimeTimer(session) {
    _workTimeTimer?.cancel();

    // Only start timer if user is working and not on break
    if (session.arrivalTime != null &&
        session.departureTime == null &&
        !session.hasActiveBreak) {
      // Force a rebuild every minute to update the display
      _workTimeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          try {
            // Just force a rebuild without calling setState
            if (context.mounted) {
              // Trigger a rebuild by calling an empty setState
              setState(() {});
            } else {
              timer.cancel();
            }
          } catch (e) {
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _stopWorkTimeTimer() {
    _workTimeTimer?.cancel();
  }

  Duration _getCurrentWorkTime(dynamic session) {
    // Always calculate work time dynamically based on current time
    if (session?.arrivalTime != null) {
      final now = DateTime.now();
      final endTime = session.departureTime ?? now;
      final totalTime = endTime.difference(session.arrivalTime);

      // Calculate total break time with proper typing
      Duration totalBreakTime = Duration.zero;
      if (session.breaks != null) {
        for (final breakPeriod in session.breaks) {
          totalBreakTime = totalBreakTime + breakPeriod.duration;
        }
      }

      return totalTime - totalBreakTime;
    }
    return session?.totalWorkTime ?? Duration.zero;
  }

  void _loadDataIfNeeded() {
    final currentState = context.read<BackendBloc>().state;

    // Load data if we're in initial or error state, or if we're missing specific data
    bool needsToLoad = false;

    if (currentState is BackendInitialState ||
        currentState is BackendErrorState) {
      needsToLoad = true;
    } else if (currentState is BackendLoadedState) {
      // Check if we have all the data we need for this screen
      if (currentState.weeklyData == null ||
          currentState.settings == null ||
          currentState.todaySession == null) {
        needsToLoad = true;
      }
    }

    if (needsToLoad) {
      context.read<BackendBloc>().add(LoadTodaySessionEvent());
      context.read<BackendBloc>().add(LoadWeeklyDataEvent());
      context.read<BackendBloc>().add(LoadSettingsEvent());
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
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Données',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Main data content
              Expanded(
                child: BlocConsumer<BackendBloc, BackendState>(
                  listener: (context, state) {
                    // Manage work time timer based on session state
                    if (state is BackendLoadedState &&
                        state.todaySession != null) {
                      final session = state.todaySession!;
                      final isWorking =
                          session.arrivalTime != null &&
                          session.departureTime == null;
                      final isOnBreak = session.hasActiveBreak;

                      if (isWorking && !isOnBreak) {
                        _startWorkTimeTimer(session);
                      } else {
                        _stopWorkTimeTimer();
                      }
                    } else {
                      _stopWorkTimeTimer();
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
                          ],
                        ),
                      );
                    } else if (state is BackendLoadedState) {
                      if (state.weeklyData == null) {
                        context.read<BackendBloc>().add(LoadWeeklyDataEvent());
                      }
                      return Column(
                        children: [
                          // Today's summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aujourd\'hui',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatCard(
                                      'Temps travaillé',
                                      WorkTimeService().formatDuration(
                                        state.todaySession != null
                                            ? _getCurrentWorkTime(
                                              state.todaySession!,
                                            )
                                            : Duration.zero,
                                      ),
                                      Icons.access_time,
                                    ),
                                    _buildStatCard(
                                      'Pauses',
                                      _formatBreaksInfo(
                                        state.todaySession,
                                        state.settings,
                                      ),
                                      Icons.coffee,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Weekly work time chart
                          WeeklyWorkTimeChart(
                            weeklyData: state.weeklyData,
                            settings: state.settings,
                          ),

                          const SizedBox(height: 16),

                          // Weekly overtime summary
                          _buildWeeklyOvertimeSummary(
                            state.weeklyData,
                            state.settings,
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Format breaks information showing count and total duration
  String _formatBreaksInfo(dynamic todaySession, dynamic settings) {
    if (todaySession == null) return '0';

    final breakCount = todaySession.breaks?.length ?? 0;
    if (breakCount == 0) return '0';

    // Calculate actual total break duration from the breaks
    Duration totalBreakDuration = Duration.zero;
    for (final breakPeriod in todaySession.breaks) {
      if (breakPeriod.endTime != null) {
        // Only count completed breaks
        totalBreakDuration += breakPeriod.duration;
      } else {
        // For ongoing breaks, use the default duration from settings
        final defaultDuration =
            settings?.breakDuration ?? Duration(minutes: 30);
        totalBreakDuration += defaultDuration;
      }
    }

    final formattedDuration = WorkTimeService().formatDuration(
      totalBreakDuration,
    );
    return '$breakCount ($formattedDuration)';
  }

  /// Build weekly overtime summary widget
  Widget _buildWeeklyOvertimeSummary(dynamic weeklyData, dynamic settings) {
    if (weeklyData == null || settings == null) {
      return const SizedBox();
    }

    // Calculate total worked hours and expected hours this week
    double totalWorkedHours = 0.0;
    double totalExpectedHours = 0.0;

    for (final dayData in weeklyData) {
      totalWorkedHours += dayData.totalWorkHours;
      totalExpectedHours += dayData.expectedWorkHours;
    }

    // Calculate overtime (can be negative)
    final overtimeHours = totalWorkedHours - totalExpectedHours;
    final isPositive = overtimeHours > 0;
    final isZero = overtimeHours.abs() < 0.05; // Less than 3 minutes difference
    final absOvertimeHours = overtimeHours.abs();

    // Format the overtime duration
    final overtimeDuration = Duration(
      hours: absOvertimeHours.floor(),
      minutes: ((absOvertimeHours - absOvertimeHours.floor()) * 60).round(),
    );
    final formattedOvertime = WorkTimeService().formatDuration(
      overtimeDuration,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bilan hebdomadaire',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temps travaillé',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      WorkTimeService().formatDuration(
                        Duration(
                          hours: totalWorkedHours.floor(),
                          minutes:
                              ((totalWorkedHours - totalWorkedHours.floor()) *
                                      60)
                                  .round(),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendu: ${WorkTimeService().formatDuration(Duration(hours: totalExpectedHours.floor(), minutes: ((totalExpectedHours - totalExpectedHours.floor()) * 60).round()))}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isZero
                        ? 'Objectif atteint'
                        : (isPositive
                            ? 'Heures supplémentaires'
                            : 'Heures manquantes'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isZero
                            ? Icons.check_circle
                            : (isPositive
                                ? Icons.trending_up
                                : Icons.trending_down),
                        color:
                            isZero
                                ? Colors.white
                                : (isPositive ? Colors.green : Colors.orange),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isZero
                            ? '✓'
                            : '${isPositive ? '+' : '-'}$formattedOvertime',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isZero
                                  ? Colors.white
                                  : (isPositive ? Colors.green : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
