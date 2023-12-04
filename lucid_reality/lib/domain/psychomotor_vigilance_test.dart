import 'dart:math';
import 'dart:ui';

import 'package:lucid_reality/ui/nextsense_colors.dart';

enum SleepStage { coreSleep, deepSleep, remSleep, awakeSleep }

const int highlyAlertMS = 300;
const int sleepyMS = 400;
const int verySleepyMS = 500;

class PsychomotorVigilanceTest {
  String title = '';
  int averageTapLatencyMs = 0;
  final DateTime dateTime;
  final List<TapTime> taps = [];
  SleepStage alertnessLevel = SleepStage.deepSleep;

  PsychomotorVigilanceTest.instance(this.dateTime);

  PsychomotorVigilanceTest(this.title, this.averageTapLatencyMs, this.dateTime, this.alertnessLevel);

  int get average {
    return taps.isEmpty
        ? 0
        : taps.map((e) => e.getSpendTime()).reduce((value, element) => value + element) ~/
            taps.length;
  }

  int get fastest {
    return taps.isEmpty
        ? 0
        : taps
            .where((element) => element.getSpendTime() != 0)
            .map((e) => e.getSpendTime())
            .reduce(min);
  }

  int get slowest {
    return taps.isEmpty ? 0 : taps.map((e) => e.getSpendTime()).reduce(max);
  }

  String get lastClickSpendTime {
    return taps.isEmpty ? '' : '${taps.last.getSpendTime()}ms';
  }
}

class TapTime {
  DateTime? startTime;
  DateTime? endTime;

  TapTime({this.startTime, this.endTime});

  int getSpendTime() {
    if (startTime == null || endTime == null) return 0;
    return endTime!.difference(startTime!).inMilliseconds;
  }
}

/// *
/// This is wrapper class for representation of tap report.
/// domain: Represent the 'x' axis data in chart
/// primary: Represent the 'y' axis data in chart
///  *
class TapData {
  final int domain;
  final int primary;

  TapData(this.domain, this.primary);
}

class BrainCheckingReport {
  final String title;
  final int responseTimeInSeconds;
  final Color color;

  BrainCheckingReport(this.title, this.responseTimeInSeconds, this.color);

  String get responseTimeInSecondsInString {
    return '$responseTimeInSeconds${title != 'Missed Responses' ? 'ms' : ''}';
  }
}

extension Alertness on SleepStage {
  Color getColor() {
    switch (this) {
      case SleepStage.coreSleep:
        return NextSenseColors.coral;
      case SleepStage.deepSleep:
        return NextSenseColors.skyBlue;
      case SleepStage.remSleep:
        return NextSenseColors.royalBlue;
      case SleepStage.awakeSleep:
        return NextSenseColors.royalPurple;
    }
  }
}
