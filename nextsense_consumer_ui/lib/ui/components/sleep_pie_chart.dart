import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';

class SleepPieChart extends StatelessWidget {
  final List<charts.Series<SleepStage, Object>> seriesList;
  final bool animate;

  const SleepPieChart(this.seriesList, {super.key, required this.animate});

  factory SleepPieChart.withSampleData() {
    return SleepPieChart(
      _createSampleData(),
      animate: false,
    );
  }
  @override
  Widget build(BuildContext context) {
    return charts.PieChart<Object>(seriesList,
        animate: animate,
      defaultRenderer: charts.ArcRendererConfig<Object>(
          arcWidth: 20,
          arcRendererDecorators: [charts.ArcLabelDecorator(
              labelPosition: charts.ArcLabelPosition.outside)]
      ),
    );
  }

  static List<charts.Series<SleepStage, Object>> _createSampleData() {
    final data = [
      SleepStage("N1", 10),
      SleepStage("N2", 15),
      SleepStage("N3", 20),
      SleepStage("WAKE", 25),
      SleepStage("REM", 30),
    ];
    return [
      charts.Series<SleepStage, Object>(
        id: 'Sleep Staging',
        domainFn: (SleepStage sales, _) => sales.stage,
        measureFn: (SleepStage sales, _) => sales.percent,
        data: data,
        labelAccessorFn: (SleepStage row, _) => row.stage.toString(),
      )
    ];
  }
}

class SleepStage {
  final String stage;
  final int percent;

  SleepStage(this.stage, this.percent);
}
