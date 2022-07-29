import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/ui/screens/signal/signal_monitoring_screen_vm.dart';
import 'package:nextsense_trial_ui/utils/algorithms.dart';

class PlotDataPoint {
  final double index;
  final double value;

  PlotDataPoint(this.index, this.value);
}

/* A view to display live plot for eeg signal. */
class EegFixedPlotData extends StatelessWidget {
  static const double defaultMaxAmplitudeMicroVolts = 50;
  static const Duration _filterSettleTime = Duration(seconds: 2);
  static const double _defaultLowPassFreq = 1;
  static const double _defaultHighPassFreq = 55;
  static const int _defaultPowerLineFreq = 60;

  final String deviceMacAddress;
  final String channelName;
  final String title;
  final int numberOfSamples;
  final double samplingFrequencyHz;
  final Duration timeWindow;
  final SignalProcessing signalProcessingType;
  final double lowCutFreqHz;
  final double highCutFreqHz;
  final int powerLineFreqHz;
  final double maxAmplitudeMicroVolts;
  final List<double> indexList = [];
  final List<PlotDataPoint> relativeEegData = [];

  EegFixedPlotData({required this.deviceMacAddress, required this.channelName, required this.title,
      required this.numberOfSamples, required this.samplingFrequencyHz, required this.timeWindow,
      this.signalProcessingType = SignalProcessing.filtered,
      this.lowCutFreqHz = _defaultLowPassFreq,
      this.highCutFreqHz = _defaultHighPassFreq,
      this.powerLineFreqHz = _defaultPowerLineFreq,
      this.maxAmplitudeMicroVolts = defaultMaxAmplitudeMicroVolts});

  Future<List<charts.Series<PlotDataPoint, double>>> _getData() async {
    // TODO(bouchard): Should get data only since the start of the impedance
    // check when that is the case.
    // Add some data to be able to hide the filter settle time in the result.
    List<double> currentEegData;
    // Filter the data.
    if (signalProcessingType == SignalProcessing.filtered) {
      currentEegData = await NextsenseBase.getChannelData(macAddress: deviceMacAddress,
          channelName: channelName, duration: timeWindow + _filterSettleTime, fromDatabase: false);
      // currentEegData = device.deviceData.eeg.eegChannels[channelIndex].getRecentData(
      //     numberOfSamples + (samplingFrequencyHz.round() * _filterSettleTime.inSeconds));
      // Make sure the high cut off is not higher than the actual signal.
      double effectiveHighCutFreq = highCutFreqHz;
      if (samplingFrequencyHz / 2 < highCutFreqHz) {
        effectiveHighCutFreq = samplingFrequencyHz / 2 - 1;
      }
      if (effectiveHighCutFreq > powerLineFreqHz) {
        currentEegData = Algorithms.filterNotch(
            currentEegData, samplingFrequencyHz, powerLineFreqHz, /*notchWidth=*/ 4, /*order=*/ 2);
      }
      currentEegData = Algorithms.filterBandpass(
          currentEegData, samplingFrequencyHz, lowCutFreqHz, highCutFreqHz, /*order=*/ 2);
      // Remove some part of the data to account for the filter settle time.
      currentEegData =
          currentEegData.sublist([0, currentEegData.length - numberOfSamples].reduce(max));
    } else {
      currentEegData = await NextsenseBase.getChannelData(macAddress: deviceMacAddress,
          channelName: channelName, duration: timeWindow + _filterSettleTime, fromDatabase: false);
    }
    // Display the X axis in seconds.
    double samplesToTimeRatio = timeWindow.inSeconds / numberOfSamples;
    // Load an array with the data indexed by relative seconds.
    for (int i = 0; i < currentEegData.length; ++i) {
      relativeEegData.add(new PlotDataPoint(i * samplesToTimeRatio, currentEegData[i]));
    }
    return [
      new charts.Series<PlotDataPoint, double>(
        id: 'EEG',
        domainFn: (PlotDataPoint points, _) => points.index,
        measureFn: (PlotDataPoint points, _) => points.value,
        data: relativeEegData,
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      )
    ];
  }

  Future<Widget> _buildLineChart() async {
    // Create the ticks to be used the domain axis.
    final staticAmplitudeTicks = <charts.TickSpec<double>>[];
    for (int i = 0; i < 9; ++i) {
      staticAmplitudeTicks.add(new charts.TickSpec(maxAmplitudeMicroVolts * ((i - 4) / 4)));
    }
    return new charts.LineChart(
      await _getData(),
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
    return FutureBuilder<Widget>(
        future: _buildLineChart(),
        builder: (context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return CircularProgressIndicator();
          }
        });
    // if (device.deviceData.eeg.sampleMetadataList.isEmpty) {
    //   return Center(
    //     child: Text(
    //       "No data available, please make sure the device is in range.",
    //       style: Theme.of(context).textTheme.bodyText2,
    //       textAlign: TextAlign.center,
    //     ),
    //   );
    // } else {
    //   return _buildLineChart();
    // }
  }
}
