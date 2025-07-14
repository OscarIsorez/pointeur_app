import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';
import 'package:pointeur_app/UI/widgets/weekly_work_chart.dart';

class DataScreenContent extends StatefulWidget {
  const DataScreenContent({super.key});

  @override
  State<DataScreenContent> createState() => _DataScreenContentState();
}

class _DataScreenContentState extends State<DataScreenContent>
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
                child: BlocBuilder<BackendBloc, BackendState>(
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
                                        state.todaySession?.totalWorkTime ??
                                            Duration.zero,
                                      ),
                                      Icons.access_time,
                                    ),
                                    _buildStatCard(
                                      'Pauses',
                                      '${state.todaySession?.breaks.length ?? 0}',
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
}
