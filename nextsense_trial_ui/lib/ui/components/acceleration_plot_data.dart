import 'package:flutter/material.dart';

import 'package:charts_flutter/flutter.dart' as charts;

import 'package:nextsense_base/nextsense_base.dart';

/* Acceleration data class. */
class AccelerationData implements Comparable<AccelerationData> {
  final int x;
  final int y;
  final int z;
  final DateTime timestamp;

  AccelerationData({required this.x, required this.y, required this.z, required this.timestamp});

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

  int getZ() {
    return z;
  }

  int getTimestampMs() {
    return timestamp.millisecondsSinceEpoch;
  }

  List<int> asList() {
    return [x, y, z];
  }

  List<int> asListWithTimestamp() {
    return [x, y, z, timestamp.millisecondsSinceEpoch];
  }

  @override
  int compareTo(AccelerationData other) {
    return timestamp.difference(other.timestamp).inMilliseconds;
  }
}

/* A view to display live plot for eeg signal. */
class AccelerationPlotData extends StatelessWidget {
  final Duration timeWindow;
  final String deviceMacAddress;
  final List<String> accChannelNames;

  AccelerationPlotData({required this.timeWindow, required this.deviceMacAddress,
    required this.accChannelNames});

  Future<List<charts.Series<AccelerationData, DateTime>>> _getData() async {
    List<int> timestamps = await NextsenseBase.getTimestampsData(
        macAddress: deviceMacAddress, duration: timeWindow);
    List<int> accXData = await NextsenseBase.getAccChannelData(macAddress: deviceMacAddress,
        channelName: 'x', duration: timeWindow, fromDatabase: false);
    List<int> accYData = await NextsenseBase.getAccChannelData(macAddress: deviceMacAddress,
        channelName: 'y', duration: timeWindow, fromDatabase: false);
    List<int> accZData = await NextsenseBase.getAccChannelData(macAddress: deviceMacAddress,
        channelName: 'z', duration: timeWindow, fromDatabase: false);
    List<AccelerationData> accelerations = [];
    for (int i = 0; i < timestamps.length; ++i) {
      accelerations.add(AccelerationData(x: accXData[i].toInt(), y: accYData[i].toInt(),
          z: accZData[i].toInt(), timestamp:
          DateTime.fromMillisecondsSinceEpoch(timestamps[i].toInt())));
    }
    return [
      new charts.Series<AccelerationData, DateTime>(
        id: 'X',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (AccelerationData acc, _) => acc.timestamp,
        measureFn: (AccelerationData acc, _) => acc.x,
        data: accelerations,
      ),
      new charts.Series<AccelerationData, DateTime>(
        id: 'Y',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (AccelerationData acc, _) => acc.timestamp,
        measureFn: (AccelerationData acc, _) => acc.y,
        data: accelerations,
      ),
      new charts.Series<AccelerationData, DateTime>(
        id: 'Z',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (AccelerationData acc, _) => acc.timestamp,
        measureFn: (AccelerationData acc, _) => acc.z,
        data: accelerations,
      )
    ];
  }

  Future<Widget> _buildLineChart() async {
    return new charts.TimeSeriesChart(
      await _getData(),
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
    print("build start");
    return FutureBuilder<Widget>(
        future: _buildLineChart(),
        builder: (context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            print("build have data");
            return snapshot.data!;
          } else {

            return CircularProgressIndicator();
          }
        });
  }
}
