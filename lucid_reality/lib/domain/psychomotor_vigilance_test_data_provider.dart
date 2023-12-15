import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class PsychomotorVigilanceTestDataProvider {
  final List<PsychomotorVigilanceTest> _brainCheckingResult = <PsychomotorVigilanceTest>[];
  final _results = <PsychomotorVigilanceTestReport>[];

  PsychomotorVigilanceTestDataProvider() {
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
        Alertness.highlyAlert,
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
        Alertness.drowsy,
      ),
    );
  }

  List<PsychomotorVigilanceTest> getData() {
    return _brainCheckingResult;
  }

  List<PsychomotorVigilanceTestReport> getReportData() {
    return _results;
  }

  void add(PsychomotorVigilanceTest psychomotorVigilanceTest) {
    _brainCheckingResult.insert(0, psychomotorVigilanceTest);
  }

  void generateReport(PsychomotorVigilanceTest psychomotorVigilanceTest) {
    _results.clear();
    final average = psychomotorVigilanceTest.average;
    final fastest = psychomotorVigilanceTest.fastest;
    final slowest = psychomotorVigilanceTest.slowest;
    _results.add(PsychomotorVigilanceTestReport(
        'Average response time', average, NextSenseColors.royalPurple));
    _results
        .add(PsychomotorVigilanceTestReport('Fastest response', fastest, NextSenseColors.skyBlue));
    _results
        .add(PsychomotorVigilanceTestReport('Slowest response', slowest, NextSenseColors.coral));
    final missed = psychomotorVigilanceTest.taps.where((element) => element == 0).length;
    _results
        .add(PsychomotorVigilanceTestReport('Missed Responses', missed, NextSenseColors.royalBlue));
    if (psychomotorVigilanceTest.title.isEmpty) {
      switch (average) {
        case <= highlyAlertMS:
          psychomotorVigilanceTest.title = "Highly Alert";
          psychomotorVigilanceTest.averageTapLatencyMs = average;
          psychomotorVigilanceTest.alertnessLevel = Alertness.highlyAlert;
          break;
        case <= sleepyMS && > highlyAlertMS:
          psychomotorVigilanceTest.title = "Alert";
          psychomotorVigilanceTest.averageTapLatencyMs = average;
          psychomotorVigilanceTest.alertnessLevel = Alertness.alert;
          break;
        case <= verySleepyMS && > sleepyMS:
          psychomotorVigilanceTest.title = "Drowsy";
          psychomotorVigilanceTest.averageTapLatencyMs = average;
          psychomotorVigilanceTest.alertnessLevel = Alertness.drowsy;
          break;
        case > verySleepyMS:
          psychomotorVigilanceTest.title = "Very Drowsy";
          psychomotorVigilanceTest.averageTapLatencyMs = average;
          psychomotorVigilanceTest.alertnessLevel = Alertness.veryDrowsy;
          break;
        default:
          psychomotorVigilanceTest.title = "Alert";
          psychomotorVigilanceTest.averageTapLatencyMs = average;
          psychomotorVigilanceTest.alertnessLevel = Alertness.alert;
      }
    }
  }
}
