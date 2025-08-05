import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/models/chart_period.dart';
import 'package:pointeur_app/services/work_time_service.dart';

class WorkTimeChart extends StatefulWidget {
  final List<WorkDayData>? allWorkData;
  final WorkSettings? settings;

  const WorkTimeChart({super.key, this.allWorkData, this.settings});

  @override
  State<WorkTimeChart> createState() => _WorkTimeChartState();
}

class _WorkTimeChartState extends State<WorkTimeChart> {
  ChartPeriod _selectedPeriod = ChartPeriod.currentWeek;

  // Colors for different work statuses
  final Color underWorkedColor = Colors.red.shade400;
  final Color exactWorkedColor = AppColors.primaryTeal;
  final Color overWorkedColor = Colors.green.shade400;
  final Color noWorkColor = Colors.grey.shade400;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with period selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Temps de travail',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 200,
            child:
                widget.allWorkData == null
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : _buildChart(),
          ),

          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChartPeriod>(
          value: _selectedPeriod,
          isDense: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.primaryTealDark,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
          items:
              ChartPeriod.values.map((period) {
                return DropdownMenuItem<ChartPeriod>(
                  value: period,
                  child: Text(
                    period.shortName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              }).toList(),
          onChanged: (ChartPeriod? newPeriod) {
            if (newPeriod != null) {
              setState(() {
                _selectedPeriod = newPeriod;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildChart() {
    final chartData = _getChartData();

    return AspectRatio(
      aspectRatio: 2.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 20;
          final barCount = chartData.length;

          // Ajuster la largeur selon le nombre de barres
          double barsWidth;
          double barsSpace;

          if (_selectedPeriod == ChartPeriod.currentWeek) {
            // Pour la semaine : barres plus larges
            final totalBarsWidth = availableWidth * 0.7;
            final totalSpaceWidth = availableWidth * 0.3;
            barsWidth = totalBarsWidth / barCount;
            barsSpace =
                barCount > 1
                    ? (totalSpaceWidth / (barCount - 1)).toDouble()
                    : 0.0;
          } else {
            // Pour 4 semaines et mois : barres plus fines et plus serrées
            barsWidth = availableWidth / (barCount * 1.5);
            barsSpace = barsWidth * 0.5;
          }

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = chartData[groupIndex];
                    final expectedHours =
                        widget.settings?.dailyWorkHours ?? 8.0;
                    return BarTooltipItem(
                      '${data.label.isEmpty ? "${data.date.day}/${data.date.month}" : data.label}\n${_formatToHHMM(rod.toY)} / ${_formatToHHMM(expectedHours)}',
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
                    getTitlesWidget:
                        (value, meta) => _bottomTitles(value, meta, chartData),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: _leftTitles,
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
              barGroups: _buildBarGroups(chartData, barsWidth),
            ),
          );
        },
      ),
    );
  }

  List<ChartDataPoint> _getChartData() {
    if (widget.allWorkData == null || widget.allWorkData!.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final filteredData = <WorkDayData>[];

    switch (_selectedPeriod) {
      case ChartPeriod.currentWeek:
        // Données de la semaine courante (lundi à dimanche)
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        filteredData.addAll(
          widget.allWorkData!.where((data) {
            return data.date.isAfter(
                  startOfWeek.subtract(const Duration(days: 1)),
                ) &&
                data.date.isBefore(endOfWeek.add(const Duration(days: 1)));
          }),
        );
        break;

      case ChartPeriod.lastFourWeeks:
        // Données des 4 dernières semaines (28 jours)
        final startDate = now.subtract(const Duration(days: 28));
        filteredData.addAll(
          widget.allWorkData!.where((data) {
            return data.date.isAfter(
              startDate.subtract(const Duration(days: 1)),
            );
          }),
        );
        break;

      case ChartPeriod.currentMonth:
        // Données du mois courant (du 1er au dernier jour)
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        filteredData.addAll(
          widget.allWorkData!.where((data) {
            return data.date.isAfter(
                  startOfMonth.subtract(const Duration(days: 1)),
                ) &&
                data.date.isBefore(endOfMonth.add(const Duration(days: 1)));
          }),
        );
        break;
    }

    // Convertir en points de données pour le graphique
    if (_selectedPeriod == ChartPeriod.currentWeek) {
      return _buildWeeklyChartData(filteredData);
    } else {
      return _buildDailyChartData(filteredData);
    }
  }

  List<ChartDataPoint> _buildWeeklyChartData(List<WorkDayData> data) {
    final weekData = List.filled(7, 0.0);
    final weekLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    for (final dayData in data) {
      final weekday = dayData.date.weekday;
      final arrayIndex = weekday - 1;
      if (arrayIndex >= 0 && arrayIndex < 7) {
        weekData[arrayIndex] = dayData.totalWorkHours;
      }
    }

    return List.generate(7, (index) {
      return ChartDataPoint(
        value: weekData[index],
        label: weekLabels[index],
        date: DateTime.now().subtract(
          Duration(days: DateTime.now().weekday - 1 - index),
        ),
      );
    });
  }

  List<ChartDataPoint> _buildDailyChartData(List<WorkDayData> data) {
    final now = DateTime.now();
    final chartData = <ChartDataPoint>[];

    if (_selectedPeriod == ChartPeriod.lastFourWeeks) {
      // Pour 4 semaines : créer 28 points (un par jour)
      final startDate = now.subtract(
        const Duration(days: 27),
      ); // 28 jours incluant aujourd'hui

      for (int i = 0; i < 28; i++) {
        final currentDate = startDate.add(Duration(days: i));
        final dayData = data.firstWhere(
          (d) =>
              d.date.year == currentDate.year &&
              d.date.month == currentDate.month &&
              d.date.day == currentDate.day,
          orElse:
              () => WorkDayData(
                date: currentDate,
                totalWorkTime: Duration.zero,
                expectedWorkTime: Duration.zero,
                surplus: Duration.zero,
                totalBreakTime: Duration.zero,
                isComplete: false,
              ),
        );

        // Afficher seulement certaines dates pour éviter l'encombrement
        String label = '';
        if (i % 7 == 0 || i == 27) {
          // Afficher chaque semaine + le dernier jour
          label = '${currentDate.day}/${currentDate.month}';
        }

        chartData.add(
          ChartDataPoint(
            value: dayData.totalWorkHours,
            label: label,
            date: currentDate,
          ),
        );
      }
    } else if (_selectedPeriod == ChartPeriod.currentMonth) {
      // Pour le mois courant : créer un point par jour du mois
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysInMonth = endOfMonth.day;

      for (int day = 1; day <= daysInMonth; day++) {
        final currentDate = DateTime(now.year, now.month, day);
        final dayData = data.firstWhere(
          (d) =>
              d.date.year == currentDate.year &&
              d.date.month == currentDate.month &&
              d.date.day == currentDate.day,
          orElse:
              () => WorkDayData(
                date: currentDate,
                totalWorkTime: Duration.zero,
                expectedWorkTime: Duration.zero,
                surplus: Duration.zero,
                totalBreakTime: Duration.zero,
                isComplete: false,
              ),
        );

        // Afficher seulement certains jours pour éviter l'encombrement
        String label = '';
        if (day == 1 || day % 5 == 0 || day == daysInMonth) {
          // 1er, chaque 5 jours, dernier
          label = '$day';
        }

        chartData.add(
          ChartDataPoint(
            value: dayData.totalWorkHours,
            label: label,
            date: currentDate,
          ),
        );
      }
    }

    return chartData;
  }

  List<BarChartGroupData> _buildBarGroups(
    List<ChartDataPoint> chartData,
    double barsWidth,
  ) {
    final expectedHours = widget.settings?.dailyWorkHours ?? 8.0;

    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      final color = _getBarColor(dataPoint.value, expectedHours);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dataPoint.value,
            color: color,
            width: barsWidth,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget _bottomTitles(
    double value,
    TitleMeta meta,
    List<ChartDataPoint> chartData,
  ) {
    const style = TextStyle(
      fontSize: 10,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );

    final index = value.toInt();
    if (index >= 0 && index < chartData.length) {
      return SideTitleWidget(
        meta: meta,
        child: Text(chartData[index].label, style: style),
      );
    }

    return const SizedBox();
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }
    const style = TextStyle(fontSize: 10, color: Colors.white);
    return SideTitleWidget(
      meta: meta,
      child: Text('${value.toInt()}h', style: style),
    );
  }

  double _getMaxY() {
    final expectedHours = widget.settings?.dailyWorkHours ?? 8.0;
    return (expectedHours * 1.5).clamp(10.0, 16.0);
  }

  Color _getBarColor(double workedHours, double expectedHours) {
    if (workedHours == 0) {
      return noWorkColor;
    } else if (workedHours < expectedHours * 0.9) {
      return underWorkedColor;
    } else if (workedHours <= expectedHours * 1.1) {
      return exactWorkedColor;
    } else {
      return overWorkedColor;
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

class ChartDataPoint {
  final double value;
  final String label;
  final DateTime date;

  ChartDataPoint({
    required this.value,
    required this.label,
    required this.date,
  });
}
