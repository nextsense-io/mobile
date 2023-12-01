import 'dart:math';
import 'dart:ui';

import 'package:lucid_reality/ui/nextsense_colors.dart';

enum ResultType { coreSleep, deepSleep, remSleep, awakeSleep }

const int highlyAlertMS = 300;
const int sleepyMS = 400;
const int verySleepyMS = 500;

class BrainChecking {
  String title = '';
  int spendTime = 0;
  final DateTime dateTime;
  final List<TapTime> taps = [];
  ResultType type = ResultType.deepSleep;

  BrainChecking.instance(this.dateTime);

  BrainChecking(this.title, this.spendTime, this.dateTime, this.type);

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

/// Sample linear data type.
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

extension ColorBaseOnType on ResultType {
  Color getColor() {
    switch (this) {
      case ResultType.coreSleep:
        return NextSenseColors.coreSleep;
      case ResultType.deepSleep:
        return NextSenseColors.deepSleep;
      case ResultType.remSleep:
        return NextSenseColors.remSleep;
      case ResultType.awakeSleep:
        return NextSenseColors.awakeSleep;
    }
  }
}
