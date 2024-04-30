import 'dart:math';
import 'dart:ui';

import 'package:lucid_reality/domain/pvt_result.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

enum Alertness { drowsy, alert, veryDrowsy, highlyAlert }

const int highlyAlertMS = 300;
const int sleepyMS = 400;
const int verySleepyMS = 500;

extension GeneratePVTResultData on int {
  void generatePVTResultData(PsychomotorVigilanceTest psychomotorVigilanceTest) {
    psychomotorVigilanceTest.averageTapLatencyMs = this;
    switch (this) {
      case <= highlyAlertMS:
        psychomotorVigilanceTest.title = "Highly Alert";
        psychomotorVigilanceTest.alertnessLevel = Alertness.highlyAlert;
        break;
      case <= sleepyMS && > highlyAlertMS:
        psychomotorVigilanceTest.title = "Alert";
        psychomotorVigilanceTest.alertnessLevel = Alertness.alert;
        break;
      case <= verySleepyMS && > sleepyMS:
        psychomotorVigilanceTest.title = "Drowsy";
        psychomotorVigilanceTest.alertnessLevel = Alertness.drowsy;
        break;
      case > verySleepyMS:
        psychomotorVigilanceTest.title = "Very Drowsy";
        psychomotorVigilanceTest.alertnessLevel = Alertness.veryDrowsy;
        break;
      default:
        psychomotorVigilanceTest.title = "Alert";
        psychomotorVigilanceTest.alertnessLevel = Alertness.alert;
    }
  }
}

class PsychomotorVigilanceTest {
  String _title = '';
  int _averageTapLatencyMs = 0;
  int _missedResponses = 0;
  final DateTime _creationDate;
  final List<int> _taps = <int>[];
  Alertness _alertnessLevel = Alertness.alert;

  String get title => _title;

  int get averageTapLatencyMs => _averageTapLatencyMs;

  int get missedResponses => _missedResponses;

  DateTime get creationDate => _creationDate;

  List<int> get taps => _taps;

  Alertness get alertnessLevel => _alertnessLevel;

  PsychomotorVigilanceTest.getInstance(this._creationDate);

  PsychomotorVigilanceTest(
      this._title, this._averageTapLatencyMs, this._creationDate, this._alertnessLevel);

  set alertnessLevel(Alertness value) {
    _alertnessLevel = value;
  }

  set averageTapLatencyMs(int value) {
    _averageTapLatencyMs = value;
  }

  set title(String value) {
    _title = value;
  }

  int get average {
    return taps.isEmpty ? 0 : taps.reduce((value, element) => value + element) ~/ taps.length;
  }

  int get fastest {
    return taps.isEmpty ? 0 : taps.where((element) => element != 0).reduce(min);
  }

  int get slowest {
    return taps.isEmpty ? 0 : taps.reduce(max);
  }

  String get lastClickSpendTime {
    return taps.isEmpty ? '' : '${taps.last}ms';
  }

  set missedResponses(int value) {
    _missedResponses = value;
  }

  void addMissedResponses() {
    _missedResponses += 1;
  }

  PVTResult toPVTResult() {
    final PVTResult pvtResult = PVTResult();
    pvtResult.setAverageTapLatencyMs(average);
    pvtResult.setTimeInterval(_creationDate.millisecondsSinceEpoch);
    if (_taps.isNotEmpty) {
      pvtResult.setReactions(_taps);
    }
    pvtResult.setMissedResponses(_missedResponses);
    return pvtResult;
  }

  factory PsychomotorVigilanceTest.fromPVTResult(PVTResult pvtResult) {
    final instance = PsychomotorVigilanceTest.getInstance(
        DateTime.fromMillisecondsSinceEpoch(pvtResult.getTimeInterval() ?? 0));
    instance.taps.addAll(pvtResult.getReactions());
    pvtResult.getAverageTapLatencyMs().generatePVTResultData(instance);
    instance.missedResponses = pvtResult.getMissedResponses();
    return instance;
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

  set endTime(DateTime? value) {
    _endTime = value;
  }

  set startTime(DateTime? value) {
    _startTime = value;
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
