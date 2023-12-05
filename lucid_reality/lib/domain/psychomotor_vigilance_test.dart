import 'dart:math';
import 'dart:ui';

import 'package:lucid_reality/ui/nextsense_colors.dart';

enum Alertness { drowsy, alert, veryDrowsy, highlyAlert }

const int highlyAlertMS = 300;
const int sleepyMS = 400;
const int verySleepyMS = 500;

class PsychomotorVigilanceTest {
  String _title = '';
  int _averageTapLatencyMs = 0;
  final DateTime _creationDate;
  final List<TapTime> _taps = <TapTime>[];
  Alertness _alertnessLevel = Alertness.alert;

  String get title => _title;

  int get averageTapLatencyMs => _averageTapLatencyMs;

  DateTime get creationDate => _creationDate;

  List<TapTime> get taps => _taps;

  Alertness get alertnessLevel => _alertnessLevel;

  PsychomotorVigilanceTest.instance(this._creationDate);

  PsychomotorVigilanceTest(
      this._title, this._averageTapLatencyMs, this._creationDate, this._alertnessLevel);

  setTitle(String title) {
    _title = title;
  }

  setAverageTapLatencyMs(int averageTapLatencyMs) {
    _averageTapLatencyMs = averageTapLatencyMs;
  }

  setAlertnessLevel(Alertness alertnessLevel) {
    _alertnessLevel = alertnessLevel;
  }

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
  DateTime? _startTime;
  DateTime? _endTime;

  DateTime? get startTime => _startTime;

  DateTime? get endTime => _endTime;

  TapTime.getInstance(this._startTime);

  int getTapLatency() {
    if (startTime == null || endTime == null) return 0;
    return endTime!.difference(startTime!).inMilliseconds;
  }

  setStartDate(DateTime startTime) {
    _startTime = startTime;
  }

  setEndDate(DateTime endTime) {
    _endTime = endTime;
  }
}

class PsychomotorVigilanceTestReport {
  final String _title;
  final int _responseTimeInSeconds;
  final Color _color;

  String get title => _title;

  Color get color => _color;

  PsychomotorVigilanceTestReport(this._title, this._responseTimeInSeconds, this._color);

  String get responseTimeInSecondsInString {
    return '$_responseTimeInSeconds${_title != 'Missed Responses' ? 'ms' : ''}';
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
