import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/models/work_settings.dart';

class WeeklyWorkTimeChart extends StatefulWidget {
  const WeeklyWorkTimeChart({super.key});

  @override
  State<WeeklyWorkTimeChart> createState() => _WeeklyWorkTimeChartState();
}

class _WeeklyWorkTimeChartState extends State<WeeklyWorkTimeChart> {
  // Colors for different work statuses
  final Color underWorkedColor = Colors.red.shade400; // Less than expected
  final Color exactWorkedColor = AppColors.primaryTeal; // Met expectation
  final Color overWorkedColor = Colors.green.shade400; // More than expected
  final Color noWorkColor = Colors.grey.shade400; // No work/day off

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 10,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Lun';
        break;
      case 1:
        text = 'Mar';
        break;
      case 2:
        text = 'Mer';
        break;
      case 3:
        text = 'Jeu';
        break;
      case 4:
        text = 'Ven';
        break;
      case 5:
        text = 'Sam';
        break;
      case 6:
        text = 'Dim';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(meta: meta, child: Text(text, style: style));
  }

  Widget leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }
    const style = TextStyle(fontSize: 10, color: Colors.white);
    return SideTitleWidget(
      meta: meta,
      child: Text('${value.toInt()}h', style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackendBloc, BackendState>(
      builder: (context, state) {
        if (state is! BackendLoadedState) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temps de travail hebdomadaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 2.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barsSpace = 4.0 * constraints.maxWidth / 400;
                      final barsWidth = 20.0 * constraints.maxWidth / 400;
                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.center,
                          maxY: _getMaxY(state.settings),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => Colors.black87,
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                final dayName = _getDayName(groupIndex);
                                final hours = rod.toY;
                                final expectedHours =
                                    state.settings?.dailyWorkHours ?? 8.0;
                                return BarTooltipItem(
                                  '$dayName\n${hours.toStringAsFixed(1)}h / ${expectedHours}h',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: bottomTitles,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: leftTitles,
                                interval: 2,
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            checkToShowHorizontalLine:
                                (value) => value % 2 == 0,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  strokeWidth: 1,
                                ),
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),
                          groupsSpace: barsSpace,
                          barGroups: _getWeeklyData(state, barsWidth),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  double _getMaxY(WorkSettings? settings) {
    final expectedHours = settings?.dailyWorkHours ?? 8.0;
    // Set max to 1.5x expected hours or minimum 10 hours
    return (expectedHours * 1.5).clamp(10.0, 16.0);
  }

  String _getDayName(int dayIndex) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[dayIndex];
  }

  List<BarChartGroupData> _getWeeklyData(
    BackendLoadedState state,
    double barsWidth,
  ) {
    final settings = state.settings;
    final expectedHours = settings?.dailyWorkHours ?? 8.0;

    // Get current week sessions (mock data for now - replace with actual weekly data)
    final weeklyHours =
        _getMockWeeklyData(); // Replace this with actual data from state

    return List.generate(7, (index) {
      final workedHours = weeklyHours[index];
      final color = _getBarColor(workedHours, expectedHours);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: workedHours,
            color: color,
            width: barsWidth,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Color _getBarColor(double workedHours, double expectedHours) {
    if (workedHours == 0) {
      return noWorkColor; // No work
    } else if (workedHours < expectedHours * 0.9) {
      return underWorkedColor; // Less than 90% of expected
    } else if (workedHours <= expectedHours * 1.1) {
      return exactWorkedColor; // Within 10% of expected
    } else {
      return overWorkedColor; // More than 110% of expected
    }
  }

  // Mock data - replace with actual weekly data from your backend
  List<double> _getMockWeeklyData() {
    // This should be replaced with actual data from your WorkSession repository
    // For now, returning mock data to demonstrate the chart
    return [7.5, 8.2, 0.0, 9.1, 7.8, 0.0, 0.0]; // Mon-Sun
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Objectif atteint', exactWorkedColor),
        _buildLegendItem('Insuffisant', underWorkedColor),
        _buildLegendItem('Dépassé', overWorkedColor),
        _buildLegendItem('Pas travaillé', noWorkColor),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
