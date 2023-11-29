import 'dart:math';

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
    print('Length1=>${_brainCheckingResult.length}');
    add(brainChecking);
    print('Length2=>${_brainCheckingResult.length}');
    final average = brainChecking.taps
            .map((e) => e.getSpendTime())
            .reduce((value, element) => value + element) ~/
        brainChecking.taps.length;
    _results.add(BrainCheckingReport('Average response time', average, NextSenseColors.awakeSleep));
    final fastest = brainChecking.taps
        .where((element) => element.getSpendTime() != 0)
        .map((e) => e.getSpendTime())
        .reduce(min);
    _results.add(BrainCheckingReport('Fastest response', fastest, NextSenseColors.deepSleep));
    final slowest = brainChecking.taps.map((e) => e.getSpendTime()).reduce(max);
    _results.add(BrainCheckingReport('Slowest response', slowest, NextSenseColors.coreSleep));
    final missed = brainChecking.taps
        .where((element) => element.startTime == null || element.endTime == null)
        .length;
    _results.add(BrainCheckingReport('Missed Responses', missed, NextSenseColors.remSleep));
  }
}
