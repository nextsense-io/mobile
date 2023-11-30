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
    add(brainChecking);
    _results.add(BrainCheckingReport('Average response time', brainChecking.average, NextSenseColors.awakeSleep));
    _results.add(BrainCheckingReport('Fastest response', brainChecking.fastest, NextSenseColors.deepSleep));
    _results.add(BrainCheckingReport('Slowest response', brainChecking.slowest, NextSenseColors.coreSleep));
    final missed = brainChecking.taps
        .where((element) => element.startTime == null || element.endTime == null)
        .length;
    _results.add(BrainCheckingReport('Missed Responses', missed, NextSenseColors.remSleep));
  }
}
