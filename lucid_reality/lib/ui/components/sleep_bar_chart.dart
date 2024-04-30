import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';

class DaySleepStage {
  final int dayOfWeekIndex;
  final String dayOfWeek;
  final String lucidSleepStage;
  final int durationMinutes;
  final Color color;

  DaySleepStage({required this.dayOfWeekIndex, required this.dayOfWeek,
    required this.lucidSleepStage, required this.durationMinutes, required this.color});
}

class SleepBarChart extends StatelessWidget {
  final List<charts.Series<DaySleepStage, String>> seriesList;
  final bool animate;

  const SleepBarChart(this.seriesList, {super.key, required this.animate});

  factory SleepBarChart.withData(List<DaySleepStage> data) {
    return SleepBarChart(
      _createData(data),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new charts.BarChart(
      seriesList,
      animate: animate,
      // Configure a stroke width to enable borders on the bars.
      defaultRenderer: new charts.BarRendererConfig(
          groupingType: charts.BarGroupingType.stacked, strokeWidthPx: 2.0, maxBarWidthPx: 16,
          cornerStrategy: const charts.ConstCornerStrategy(50)),
    );
  }

  static List<charts.Series<DaySleepStage, String>> _createData(
      List<DaySleepStage> sleepStages) {
    return [
      charts.Series<DaySleepStage, String>(
        id: 'Sleep Staging',
        domainFn: (DaySleepStage sleepStage, _) => sleepStage.dayOfWeek,
        measureFn: (DaySleepStage sleepStage, _) => sleepStage.durationMinutes / 60,
        data: sleepStages,
        colorFn: (DaySleepStage sleepStage, __) => charts.ColorUtil.fromDartColor(
            sleepStage.color),
        fillColorFn: (DaySleepStage sleepStage, __) => charts.ColorUtil.fromDartColor(
            sleepStage.color),
        labelAccessorFn: (DaySleepStage sleepStage, _) => sleepStage.lucidSleepStage,
        outsideLabelStyleAccessorFn: (_, __) => const charts.TextStyleSpec(
          fontSize: 16,
          color: charts.MaterialPalette.white,
          // fontFamily: 'MyFont'
        ),
      )
    ];
  }
}
