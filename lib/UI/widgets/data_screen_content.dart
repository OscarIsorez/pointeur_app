import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/work_session_bloc.dart';
import 'package:pointeur_app/bloc/work_session_events.dart';
import 'package:pointeur_app/bloc/work_session_states.dart';
import 'package:pointeur_app/bloc/settings_bloc.dart';
import 'package:pointeur_app/bloc/settings_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/UI/widgets/work_time_chart.dart';
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

    // Start timer if user has an active session (working OR on break)
    if (session.arrivalTime != null && session.departureTime == null) {
      // Force a rebuild every minute to update the display (work time AND break time)
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
          if (breakPeriod.endTime != null) {
            // Count completed breaks using their actual duration
            totalBreakTime = totalBreakTime + breakPeriod.duration;
          } else {
            // For ongoing breaks, calculate time elapsed since start
            final elapsedBreakTime = now.difference(breakPeriod.startTime);
            totalBreakTime = totalBreakTime + elapsedBreakTime;
          }
        }
      }

      return totalTime - totalBreakTime;
    }
    return session?.totalWorkTime ?? Duration.zero;
  }

  void _loadDataIfNeeded() {
    final currentState = context.read<WorkSessionBloc>().state;

    // Load data if we're in initial or error state, or if we're missing specific data
    bool needsToLoad = false;

    if (currentState is WorkSessionInitialState ||
        currentState is WorkSessionErrorState) {
      needsToLoad = true;
    } else if (currentState is WorkSessionLoadedState) {
      // Check if we have all the data we need for this screen
      if (currentState.weeklyData == null || currentState.settings == null) {
        needsToLoad = true;
      }
    }

    if (needsToLoad) {
      // Load all data from WorkSessionBloc
      context.read<WorkSessionBloc>().add(RefreshAllDataEvent());
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
        child: MultiBlocListener(
          listeners: [
            // Listen to SettingsBloc changes and update WorkSessionBloc
            BlocListener<SettingsBloc, SettingsState>(
              listener: (context, settingsState) {
                if (settingsState is SettingsLoadedState) {
                  // When settings are updated, update WorkSessionBloc with new settings
                  final workSessionState =
                      context.read<WorkSessionBloc>().state;
                  if (workSessionState is WorkSessionLoadedState) {
                    context.read<WorkSessionBloc>().add(
                      UpdateWorkSessionSettingsEvent(settingsState.settings),
                    );
                  }
                }
              },
            ),
          ],
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
                  child: BlocConsumer<WorkSessionBloc, WorkSessionState>(
                    listener: (context, sessionState) {
                      // Manage work time timer based on session state
                      if (sessionState is WorkSessionLoadedState) {
                        final session = sessionState.todaySession;
                        final isActive =
                            session.arrivalTime != null &&
                            session.departureTime == null;

                        if (isActive) {
                          _startWorkTimeTimer(session);
                        } else {
                          _stopWorkTimeTimer();
                        }
                      } else {
                        _stopWorkTimeTimer();
                      }
                    },
                    builder: (context, sessionState) {
                      // Handle loading states
                      if (sessionState is WorkSessionLoadingState) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      }

                      // Handle error states
                      if (sessionState is WorkSessionErrorState) {
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
                                sessionState.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Extract data from session state
                      final todaySession =
                          sessionState is WorkSessionLoadedState
                              ? sessionState.todaySession
                              : null;

                      final weeklyData =
                          sessionState is WorkSessionLoadedState
                              ? sessionState.weeklyData
                              : null;

                      final allWorkData =
                          sessionState is WorkSessionLoadedState
                              ? sessionState.allWorkData
                              : null;

                      final settings =
                          sessionState is WorkSessionLoadedState
                              ? sessionState.settings
                              : null;

                      final monthlySummary =
                          sessionState is WorkSessionLoadedState
                              ? sessionState.monthlySummary
                              : null;

                      // Load missing data if needed
                      if (sessionState is WorkSessionLoadedState) {
                        if (weeklyData == null) {
                          // Load weekly data if missing
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<WorkSessionBloc>().add(
                              LoadWeeklyDataEvent(),
                            );
                          });
                        }
                        if (allWorkData == null) {
                          // Load all work data if missing
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<WorkSessionBloc>().add(
                              LoadAllWorkDataEvent(),
                            );
                          });
                        }
                        if (settings == null) {
                          // Load settings if missing
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<WorkSessionBloc>().add(
                              LoadSettingsEvent(),
                            );
                          });
                        }
                        if (monthlySummary == null) {
                          // Load monthly summary if missing
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<WorkSessionBloc>().add(
                              LoadMonthlySummaryEvent(),
                            );
                          });
                        }
                      }

                      return SingleChildScrollView(
                        child: Column(
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
                                          todaySession != null
                                              ? _getCurrentWorkTime(
                                                todaySession,
                                              )
                                              : Duration.zero,
                                        ),
                                        Icons.access_time,
                                      ),
                                      _buildStatCard(
                                        'Pauses',
                                        _formatBreaksInfo(
                                          todaySession,
                                          settings,
                                        ),
                                        Icons.coffee,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Work time chart with period selector
                            WorkTimeChart(
                              allWorkData: allWorkData,
                              settings: settings,
                            ),

                            const SizedBox(height: 16),

                            // Weekly overtime summary
                            _buildWeeklyOvertimeSummary(weeklyData, settings),

                            const SizedBox(height: 16),

                            // Monthly summary
                            _buildMonthlySummary(monthlySummary, settings),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
    final now = DateTime.now();

    for (final breakPeriod in todaySession.breaks) {
      if (breakPeriod.endTime != null) {
        // Count completed breaks using their actual duration
        totalBreakDuration += breakPeriod.duration;
      } else {
        // For ongoing breaks, calculate time elapsed since start
        final elapsedBreakTime = now.difference(breakPeriod.startTime);
        totalBreakDuration += elapsedBreakTime;
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

  /// Build monthly summary widget
  Widget _buildMonthlySummary(dynamic monthlySummary, dynamic settings) {
    if (monthlySummary == null || settings == null) {
      return const SizedBox();
    }

    // Calculate total worked hours and expected hours this month
    final totalWorkedHours = monthlySummary.totalWorkHours ?? 0.0;
    final totalExpectedHours = monthlySummary.expectedWorkHours ?? 0.0;
    final workingDaysCount = monthlySummary.workingDays ?? 0;
    final completedDaysCount =
        monthlySummary.workingDays ??
        0; // Use same value since WorkSummary only tracks completed days

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

    // Calculate completion percentage
    final completionPercentage =
        workingDaysCount > 0
            ? (completedDaysCount / workingDaysCount * 100).round()
            : 0;

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
            'Bilan mensuel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar for days completed
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jours travaillés: $completedDaysCount / $workingDaysCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value:
                          workingDaysCount > 0
                              ? completedDaysCount / workingDaysCount
                              : 0,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completionPercentage >= 80
                            ? Colors.green
                            : completionPercentage >= 60
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$completionPercentage%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      completionPercentage >= 80
                          ? Colors.green
                          : completionPercentage >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Time summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temps travaillé ce mois',
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
                        ? 'Objectif mensuel atteint'
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
