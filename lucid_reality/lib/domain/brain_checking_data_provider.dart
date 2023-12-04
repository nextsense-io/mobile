import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';



class BrainCheckingDataProvider {
  final List<PsychomotorVigilanceTest> _brainCheckingResult = <PsychomotorVigilanceTest>[];
  final _results = <BrainCheckingReport>[];

  BrainCheckingDataProvider() {
    _brainCheckingResult.add(
      PsychomotorVigilanceTest(
        'Highly Alert',
        0000,
        DateTime(
          2023,
          10,
          8,
          9,
          5,
        ),
        SleepStage.awakeSleep,
      ),
    );
    _brainCheckingResult.add(
      PsychomotorVigilanceTest(
        'Sleepy',
        0000,
        DateTime(
          2023,
          10,
          7,
          20,
          35,
        ),
        SleepStage.coreSleep,
      ),
    );
  }

  List<PsychomotorVigilanceTest> getData() {
    return _brainCheckingResult;
  }

  List<BrainCheckingReport> getReportData() {
    return _results;
  }

  void add(PsychomotorVigilanceTest brainChecking) {
    _brainCheckingResult.insert(0, brainChecking);
  }

  void generateReport(PsychomotorVigilanceTest brainChecking) {
    _results.clear();
    final average = brainChecking.average;
    final fastest = brainChecking.fastest;
    final slowest = brainChecking.slowest;
    _results.add(BrainCheckingReport('Average response time', average, NextSenseColors.royalPurple));
    _results.add(BrainCheckingReport('Fastest response', fastest, NextSenseColors.skyBlue));
    _results.add(BrainCheckingReport('Slowest response', slowest, NextSenseColors.coral));
    final missed = brainChecking.taps
        .where((element) => element.startTime == null || element.endTime == null)
        .length;
    _results.add(BrainCheckingReport('Missed Responses', missed, NextSenseColors.royalBlue));
    if (brainChecking.title.isEmpty) {
      switch (average) {
        case <= highlyAlertMS:
          brainChecking.title = "Highly Alert";
          brainChecking.averageTapLatencyMs = average;
          brainChecking.alertnessLevel = SleepStage.awakeSleep;
          break;
        case <= sleepyMS && > highlyAlertMS:
          brainChecking.title = "Alert";
          brainChecking.averageTapLatencyMs = average;
          brainChecking.alertnessLevel = SleepStage.deepSleep;
          break;
        case <= verySleepyMS && > sleepyMS:
          brainChecking.title = "Drowsy";
          brainChecking.averageTapLatencyMs = average;
          brainChecking.alertnessLevel = SleepStage.coreSleep;
          break;
        case > verySleepyMS:
          brainChecking.title = "Very Drowsy";
          brainChecking.averageTapLatencyMs = average;
          brainChecking.alertnessLevel = SleepStage.coreSleep;
          break;
        default:
          brainChecking.title = "Alert";
          brainChecking.averageTapLatencyMs = average;
          brainChecking.alertnessLevel = SleepStage.deepSleep;
      }
    }
  }
}
