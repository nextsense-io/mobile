import 'package:lucid_reality/ui/nextsense_colors.dart';

import 'brain_checking.dart';

class BrainCheckingDataProvider {
  final List<BrainChecking> _brainCheckingResult = <BrainChecking>[];
  final _results = <BrainCheckingReport>[];

  BrainCheckingDataProvider() {
    _brainCheckingResult.add(
      BrainChecking(
        'Highly Alert',
        0000,
        DateTime(
          2023,
          10,
          8,
          9,
          5,
        ),
        ResultType.awakeSleep,
      ),
    );
    _brainCheckingResult.add(
      BrainChecking(
        'Sleepy',
        0000,
        DateTime(
          2023,
          10,
          7,
          20,
          35,
        ),
        ResultType.coreSleep,
      ),
    );
  }

  List<BrainChecking> getData() {
    return _brainCheckingResult;
  }

  List<BrainCheckingReport> getReportData() {
    return _results;
  }

  void add(BrainChecking brainChecking) {
    _brainCheckingResult.insert(0, brainChecking);
  }

  void generateReport(BrainChecking brainChecking) {
    _results.clear();
    final average = brainChecking.average;
    final fastest = brainChecking.fastest;
    final slowest = brainChecking.slowest;
    _results.add(BrainCheckingReport('Average response time', average, NextSenseColors.awakeSleep));
    _results.add(BrainCheckingReport('Fastest response', fastest, NextSenseColors.deepSleep));
    _results.add(BrainCheckingReport('Slowest response', slowest, NextSenseColors.coreSleep));
    final missed = brainChecking.taps
        .where((element) => element.startTime == null || element.endTime == null)
        .length;
    _results.add(BrainCheckingReport('Missed Responses', missed, NextSenseColors.remSleep));
    if (brainChecking.title.isEmpty) {
      switch (average) {
        case <= highlyAlertMS:
          brainChecking.title = "Highly Alert";
          brainChecking.spendTime = average;
          brainChecking.type = ResultType.awakeSleep;
          break;
        case <= sleepyMS && > highlyAlertMS:
          brainChecking.title = "Alert";
          brainChecking.spendTime = average;
          brainChecking.type = ResultType.deepSleep;
          break;
        case <= verySleepyMS && > sleepyMS:
          brainChecking.title = "Drowsy";
          brainChecking.spendTime = average;
          brainChecking.type = ResultType.coreSleep;
          break;
        case > verySleepyMS:
          brainChecking.title = "Very Drowsy";
          brainChecking.spendTime = average;
          brainChecking.type = ResultType.coreSleep;
          break;
        default:
          brainChecking.title = "Alert";
          brainChecking.spendTime = average;
          brainChecking.type = ResultType.deepSleep;
      }
    }
  }
}
