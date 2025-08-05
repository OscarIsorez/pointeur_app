enum ChartPeriod { currentWeek, lastFourWeeks, currentMonth }

extension ChartPeriodExtension on ChartPeriod {
  String get displayName {
    switch (this) {
      case ChartPeriod.currentWeek:
        return 'Cette semaine';
      case ChartPeriod.lastFourWeeks:
        return '4 dernières semaines';
      case ChartPeriod.currentMonth:
        return 'Ce mois';
    }
  }

  String get shortName {
    switch (this) {
      case ChartPeriod.currentWeek:
        return 'Semaine';
      case ChartPeriod.lastFourWeeks:
        return '4 semaines';
      case ChartPeriod.currentMonth:
        return 'Mois';
    }
  }
}
