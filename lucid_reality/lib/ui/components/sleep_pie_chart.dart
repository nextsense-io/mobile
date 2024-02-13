import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';

class SleepPieChart extends StatelessWidget {
  final List<charts.Series<ChartSleepStage, Object>> seriesList;
  final bool animate;
  final charts.LayoutConfig? layoutConfig;
  final int arcWidth;

  const SleepPieChart(this.seriesList,
      {super.key, required this.animate, this.arcWidth = 15, this.layoutConfig});

  factory SleepPieChart.withData(List<ChartSleepStage> data) {
    return SleepPieChart(
      _createData(data),
      animate: false,
    );
  }

  factory SleepPieChart.withDataAndChartConfig(
      {required List<ChartSleepStage> data, required int arcWidth, required int margin}) {
    return SleepPieChart(
      _createData(data),
      animate: false,
      arcWidth: arcWidth,
      layoutConfig: charts.LayoutConfig(
        leftMarginSpec: charts.MarginSpec.fixedPixel(margin),
        topMarginSpec: charts.MarginSpec.fixedPixel(margin),
        rightMarginSpec: charts.MarginSpec.fixedPixel(margin),
        bottomMarginSpec: charts.MarginSpec.fixedPixel(margin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.PieChart<Object>(
      seriesList,
      animate: animate,
      layoutConfig: layoutConfig,
      defaultRenderer: charts.ArcRendererConfig<Object>(
        arcWidth: arcWidth,
        // arcRendererDecorators: [charts.ArcLabelDecorator(
        //     labelPosition: charts.ArcLabelPosition.outside,)]
      ),
    );
  }

  static List<charts.Series<ChartSleepStage, Object>> _createData(
      List<ChartSleepStage> chartSleepStages) {
    return [
      charts.Series<ChartSleepStage, Object>(
        id: 'Sleep Staging',
        domainFn: (ChartSleepStage chartSleepStage, _) => chartSleepStage.stage,
        measureFn: (ChartSleepStage chartSleepStage, _) => chartSleepStage.percent,
        data: chartSleepStages,
        colorFn: (ChartSleepStage chartSleepStage, __) =>
            charts.ColorUtil.fromDartColor(chartSleepStage.color),
        labelAccessorFn: (ChartSleepStage chartSleepStage, _) => chartSleepStage.stage.toString(),
        outsideLabelStyleAccessorFn: (_, __) => const charts.TextStyleSpec(
          fontSize: 16,
          color: charts.MaterialPalette.white,
          // fontFamily: 'MyFont'
        ),
      )
    ];
  }
}

class ChartSleepStage {
  final String stage;
  final int percent;
  final Duration duration;
  final Color color;

  ChartSleepStage(this.stage, this.percent, this.duration, this.color);
}
