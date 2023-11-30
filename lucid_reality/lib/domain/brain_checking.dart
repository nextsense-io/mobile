import 'dart:math';
import 'dart:ui';

import 'package:lucid_reality/ui/nextsense_colors.dart';

enum ResultType { coreSleep, deepSleep, remSleep, awakeSleep }

class BrainChecking {
  final String title;
  final int spendTime;
  final DateTime dateTime;
  final ResultType type;
  final List<TapTime> taps = [];

  BrainChecking(this.title, this.spendTime, this.dateTime, this.type);

  int get average {
    return taps.map((e) => e.getSpendTime()).reduce((value, element) => value + element) ~/
        taps.length;
  }

  int get fastest {
    return taps
        .where((element) => element.getSpendTime() != 0)
        .map((e) => e.getSpendTime())
        .reduce(min);
  }

  int get slowest {
    return taps.map((e) => e.getSpendTime()).reduce(max);
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
