import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/services/work_time_service.dart';

class WeeklyWorkTimeChart extends StatefulWidget {
  final List<WorkDayData>? weeklyData;
  final WorkSettings? settings;

  const WeeklyWorkTimeChart({super.key, this.weeklyData, this.settings});

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
    // Show loading state if no data is provided
    if (widget.weeklyData == null) {
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
              aspectRatio: 3.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Better spacing calculations for 7 bars
                  final availableWidth = constraints.maxWidth - 20;
                  final totalBarsWidth =
                      availableWidth * 0.7; // Use 70% for bars
                  final totalSpaceWidth =
                      availableWidth * 0.4; // Use 30% for spacing

                  final barsWidth =
                      totalBarsWidth / 7; // Divide equally among 7 days
                  final barsSpace =
                      totalSpaceWidth / 6; // 6 spaces between 7 bars
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(widget.settings),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final dayName = _getDayName(groupIndex);
                            final hours = rod.toY;
                            final expectedHours =
                                widget.settings?.dailyWorkHours ?? 8.0;
                            return BarTooltipItem(
                              '$dayName\n${_formatToHHMM(hours)} / ${_formatToHHMM(expectedHours)}',
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
                        checkToShowHorizontalLine: (value) => value % 2 == 0,
                        getDrawingHorizontalLine:
                            (value) => FlLine(
                              color: Colors.white.withValues(alpha: 0.1),
                              strokeWidth: 1,
                            ),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      groupsSpace: barsSpace,
                      barGroups: _getWeeklyData(barsWidth),
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

  List<BarChartGroupData> _getWeeklyData(double barsWidth) {
    final settings = widget.settings;
    final expectedHours = settings?.dailyWorkHours ?? 8.0;

    // Get weekly hours from real data
    final weeklyHours = _getWeeklyHoursFromData();

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

  /// Extract weekly hours data from the passed weeklyData
  /// Returns array of 7 doubles representing Monday to Sunday work hours
  List<double> _getWeeklyHoursFromData() {
    final weeklyData = widget.weeklyData;

    if (weeklyData == null || weeklyData.isEmpty) {
      // Return zeros if no data available yet
      return List.filled(7, 0.0);
    }

    // Create array for Mon-Sun (index 0 = Monday, 6 = Sunday)
    final weeklyHours = List.filled(7, 0.0);

    for (final dayData in weeklyData) {
      // Get weekday (1 = Monday, 7 = Sunday)
      final weekday = dayData.date.weekday;
      // Convert to array index (0 = Monday, 6 = Sunday)
      final arrayIndex = weekday - 1;

      if (arrayIndex >= 0 && arrayIndex < 7) {
        weeklyHours[arrayIndex] = dayData.totalWorkHours;
      }
    }

    return weeklyHours;
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

  String _formatToHHMM(dynamic timeValue) {
    late final int hours;
    late final int minutes;

    if (timeValue is double) {
      hours = timeValue.floor();
      minutes = ((timeValue - hours) * 60).round();
    } else if (timeValue is Duration?) {
      hours = timeValue?.inHours ?? 0;
      minutes = timeValue?.inMinutes.remainder(60) ?? 0;
    } else {
      throw ArgumentError('timeValue must be either double or Duration');
    }

    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}
