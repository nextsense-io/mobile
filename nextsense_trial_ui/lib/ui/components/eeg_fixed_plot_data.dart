import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/screens/signal/signal_monitoring_screen_vm.dart';

/* A view to display live plot for eeg signal. */
class EegFixedPlotData extends StatelessWidget {
  static const double defaultMaxAmplitudeMicroVolts = 50;

  final String title;
  final double maxAmplitudeMicroVolts;
  final List<double> indexList = [];
  final List<PlotDataPoint> eegData;

  EegFixedPlotData({required this.eegData, required this.title,
      this.maxAmplitudeMicroVolts = defaultMaxAmplitudeMicroVolts});

  List<charts.Series<PlotDataPoint, double>> _getData() {
    return [
      new charts.Series<PlotDataPoint, double>(
        id: 'EEG',
        domainFn: (PlotDataPoint points, _) => points.index,
        measureFn: (PlotDataPoint points, _) => points.value,
        data: eegData,
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      )
    ];
  }

  Widget _buildLineChart() {
    // Create the ticks to be used the domain axis.
    final staticAmplitudeTicks = <charts.TickSpec<double>>[];
    for (int i = 0; i < 9; ++i) {
      staticAmplitudeTicks.add(new charts.TickSpec(maxAmplitudeMicroVolts * ((i - 4) / 4)));
    }
    return new charts.LineChart(
      _getData(),
      // If true, it apparently does not have the time to display before the next refresh.
      animate: false,
      primaryMeasureAxis: new charts.NumericAxisSpec(
          tickProviderSpec: new charts.StaticNumericTickProviderSpec(staticAmplitudeTicks)),
      domainAxis: new charts.NumericAxisSpec(
        // viewport: new charts.NumericExtents(0, timeWindow.inSeconds),
        tickProviderSpec: new charts.BasicNumericTickProviderSpec(
            zeroBound: true,
            dataIsInWholeNumbers: true,
            desiredMinTickCount: 2,
            desiredMaxTickCount: 6),
      ),
      behaviors: [
        new charts.ChartTitle(title,
            behaviorPosition: charts.BehaviorPosition.top,
            titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
            innerPadding: 24),
        new charts.ChartTitle('Time (sec)',
            behaviorPosition: charts.BehaviorPosition.bottom,
            titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
            innerPadding: 24),
        new charts.ChartTitle(
          'Signal Amplitude (uV)',
          behaviorPosition: charts.BehaviorPosition.start,
          titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildLineChart();
  }
}
