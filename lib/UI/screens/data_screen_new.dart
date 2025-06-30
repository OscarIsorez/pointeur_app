import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/UI/screens/home_screen.dart';
import 'package:pointeur_app/UI/screens/settings_screen.dart';
import 'package:pointeur_app/UI/widgets/nav_bar.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  @override
  void initState() {
    super.initState();
    // Load weekly data and monthly summary when screen opens
    context.read<BackendBloc>().add(LoadWeeklyDataEvent());
    context.read<BackendBloc>().add(LoadMonthlySummaryEvent());
    context.read<BackendBloc>().add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Les données',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // Chart
                BlocBuilder<BackendBloc, BackendState>(
                  builder: (context, state) {
                    if (state is BackendLoadingState) {
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state is BackendLoadedState &&
                        state.weeklyData != null) {
                      return _buildChart(state.weeklyData!, state.settings);
                    }

                    return _buildChart([], null);
                  },
                ),
                const SizedBox(height: 32),

                // Summary cards
                BlocBuilder<BackendBloc, BackendState>(
                  builder: (context, state) {
                    if (state is BackendLoadedState &&
                        state.monthlySummary != null) {
                      return _buildSummaryCards(context, state.monthlySummary!);
                    }
                    return _buildEmptySummaryCards(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  Widget _buildChart(List<WorkDayData> weeklyData, dynamic settings) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (weeklyData.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: TextStyle(color: AppColors.gray600, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(weeklyData),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex < weeklyData.length) {
                          final data = weeklyData[groupIndex];
                          return BarTooltipItem(
                            '${_formatDuration(data.totalWorkTime)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: _getWeekdayName(data.date.weekday),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: const TextStyle(
                              color: AppColors.gray600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < weeklyData.length) {
                            final data = weeklyData[value.toInt()];
                            return Text(
                              _getWeekdayInitial(data.date.weekday),
                              style: const TextStyle(
                                color: AppColors.gray600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.gray200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _getBarGroupsFromData(weeklyData),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  double _getMaxY(List<WorkDayData> weeklyData) {
    if (weeklyData.isEmpty) return 12;

    double max = 0;
    for (final data in weeklyData) {
      final total = data.totalWorkHours;
      if (total > max) max = total;
    }

    // Round up to nearest 2 hours and add some padding
    return ((max / 2).ceil() * 2 + 2).toDouble();
  }

  List<BarChartGroupData> _getBarGroupsFromData(List<WorkDayData> weeklyData) {
    List<BarChartGroupData> groups = [];

    for (int i = 0; i < weeklyData.length; i++) {
      final data = weeklyData[i];
      final workHours = data.totalWorkHours;
      final expectedHours = data.expectedWorkHours;

      List<BarChartRodData> rods = [];

      // Main work hours bar
      rods.add(
        BarChartRodData(
          toY: workHours,
          fromY: 0,
          color:
              workHours >= expectedHours
                  ? AppColors.primaryTeal
                  : AppColors.actionRed,
          width: 16,
          borderRadius: BorderRadius.circular(2),
        ),
      );

      groups.add(BarChartGroupData(x: i, barRods: rods));
    }

    return groups;
  }

  String _getWeekdayInitial(int weekday) {
    const initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return initials[weekday - 1];
  }

  String _getWeekdayName(int weekday) {
    const names = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return names[weekday - 1];
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}min';
    }
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Heures travaillées', AppColors.primaryTeal),
        const SizedBox(width: 20),
        _buildLegendItem('Objectif non atteint', AppColors.actionRed),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray600),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, WorkSummary summary) {
    final workTimeService = WorkTimeService();

    return Column(
      children: [
        _buildSummaryCard(
          context,
          'Total cette semaine :',
          workTimeService.formatDuration(summary.totalWorkTime),
          summary.surplus.inMilliseconds >= 0,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          context,
          'Surplus/Déficit :',
          '${summary.surplus.inMilliseconds >= 0 ? '+' : ''}${workTimeService.formatDuration(summary.surplus)}',
          summary.surplus.inMilliseconds >= 0,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          context,
          'Moyenne par jour :',
          workTimeService.formatDuration(summary.averageWorkTime),
          null,
        ),
      ],
    );
  }

  Widget _buildEmptySummaryCards(BuildContext context) {
    return Column(
      children: [
        _buildSummaryCard(context, 'Total cette semaine :', '0h00', null),
        const SizedBox(height: 16),
        _buildSummaryCard(context, 'Surplus/Déficit :', '0h00', null),
        const SizedBox(height: 16),
        _buildSummaryCard(context, 'Moyenne par jour :', '0h00', null),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    bool? isPositive,
  ) {
    Color? valueColor;
    if (isPositive != null) {
      valueColor = isPositive ? Colors.green : Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on data screen
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }
}
