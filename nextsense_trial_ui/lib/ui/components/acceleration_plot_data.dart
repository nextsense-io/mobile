import 'package:flutter/material.dart';

import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/screens/signal/signal_monitoring_screen_vm.dart';

/* A view to display live plot for eeg signal. */
class AccelerationPlotData extends HookWidget {
  final List<AccelerationData> accData;

  AccelerationPlotData({required this.accData});

  List<charts.Series<AccelerationData, DateTime>> _getData() {
    return [
      new charts.Series<AccelerationData, DateTime>(
        id: 'X',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (AccelerationData acc, _) => acc.timestamp,
        measureFn: (AccelerationData acc, _) => acc.x,
        data: accData,
      ),
      new charts.Series<AccelerationData, DateTime>(
        id: 'Y',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (AccelerationData acc, _) => acc.timestamp,
        measureFn: (AccelerationData acc, _) => acc.y,
        data: accData,
      ),
      new charts.Series<AccelerationData, DateTime>(
        id: 'Z',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (AccelerationData acc, _) => acc.timestamp,
        measureFn: (AccelerationData acc, _) => acc.z,
        data: accData,
      )
    ];
  }

  Widget _buildLineChart() {
    return new charts.TimeSeriesChart(
      _getData(),
      // If true, it apparently does not have the time to display before the
      // next refresh.
      animate: false,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      primaryMeasureAxis: new charts.NumericAxisSpec(
        tickProviderSpec: new charts.BasicNumericTickProviderSpec(
          desiredTickCount: 8,
          zeroBound: false,
        ),
      ),
      behaviors: [
        new charts.SeriesLegend(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildLineChart();
  }
}
