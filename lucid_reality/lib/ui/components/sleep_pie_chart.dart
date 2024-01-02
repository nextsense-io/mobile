import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';

class SleepPieChart extends StatelessWidget {
  final List<charts.Series<SleepStage, Object>> seriesList;
  final bool animate;

  const SleepPieChart(this.seriesList, {super.key, required this.animate});

  factory SleepPieChart.withData(List<SleepStage> data) {
    return SleepPieChart(
      _createData(data),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.PieChart<Object>(seriesList,
        animate: animate,
      defaultRenderer: charts.ArcRendererConfig<Object>(
          arcWidth: 15,
          // arcRendererDecorators: [charts.ArcLabelDecorator(
          //     labelPosition: charts.ArcLabelPosition.outside,)]
      ),
    );
  }

  static List<charts.Series<SleepStage, Object>> _createData(List<SleepStage> sleepStages) {
    return [
      charts.Series<SleepStage, Object>(
        id: 'Sleep Staging',
        domainFn: (SleepStage sleepStage, _) => sleepStage.stage,
        measureFn: (SleepStage sleepStage, _) => sleepStage.percent,
        data: sleepStages,
        colorFn: (SleepStage sleepStage, __) => charts.ColorUtil.fromDartColor(sleepStage.color),
        labelAccessorFn: (SleepStage sleepStage, _) => sleepStage.stage.toString(),
        outsideLabelStyleAccessorFn: (_, __) => const charts.TextStyleSpec(
            fontSize: 16,
            color: charts.MaterialPalette.white,
            // fontFamily: 'MyFont'
        ),
      )
    ];
  }
}

class SleepStage {
  final String stage;
  final int percent;
  final Duration duration;
  final Color color;

  SleepStage(this.stage, this.percent, this.duration, this.color);
}
