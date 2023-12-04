import 'dart:math';
import 'dart:ui';

import 'package:lucid_reality/ui/nextsense_colors.dart';

enum Alertness { drowsy, alert, veryDrowsy, highlyAlert }

const int highlyAlertMS = 300;
const int sleepyMS = 400;
const int verySleepyMS = 500;

class PsychomotorVigilanceTest {
  String title = '';
  int averageTapLatencyMs = 0;
  final DateTime dateTime;
  final List<TapTime> taps = [];
  Alertness alertnessLevel = Alertness.alert;

  PsychomotorVigilanceTest.instance(this.dateTime);

  PsychomotorVigilanceTest(
      this.title, this.averageTapLatencyMs, this.dateTime, this.alertnessLevel);

  int get average {
    return taps.isEmpty
        ? 0
        : taps.map((e) => e.getTapLatency()).reduce((value, element) => value + element) ~/
            taps.length;
  }

  int get fastest {
    return taps.isEmpty
        ? 0
        : taps
            .where((element) => element.getTapLatency() != 0)
            .map((e) => e.getTapLatency())
            .reduce(min);
  }

  int get slowest {
    return taps.isEmpty ? 0 : taps.map((e) => e.getTapLatency()).reduce(max);
  }

  String get lastClickSpendTime {
    return taps.isEmpty ? '' : '${taps.last.getTapLatency()}ms';
  }
}

class TapTime {
  DateTime? startTime;
  DateTime? endTime;

  TapTime({this.startTime, this.endTime});

  int getTapLatency() {
    if (startTime == null || endTime == null) return 0;
    return endTime!.difference(startTime!).inMilliseconds;
  }
}

class PsychomotorVigilanceTestReport {
  final String title;
  final int responseTimeInSeconds;
  final Color color;

  PsychomotorVigilanceTestReport(this.title, this.responseTimeInSeconds, this.color);

  String get responseTimeInSecondsInString {
    return '$responseTimeInSeconds${title != 'Missed Responses' ? 'ms' : ''}';
  }
}

extension AlertnessToColorValue on Alertness {
  Color getColor() {
    switch (this) {
      case Alertness.drowsy:
        return NextSenseColors.coral;
      case Alertness.alert:
        return NextSenseColors.skyBlue;
      case Alertness.veryDrowsy:
        return NextSenseColors.royalBlue;
      case Alertness.highlyAlert:
        return NextSenseColors.royalPurple;
    }
  }
}
