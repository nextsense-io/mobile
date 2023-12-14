import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/domain/pvt_result.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class PVTManager {
  final _logger = CustomLogPrinter('PVTManager');
  final firebaseRealTimeDb = getIt<LucidUiFirebaseRealtimeDBManager>();
  List<PsychomotorVigilanceTest> _psychomotorVigilanceTest = <PsychomotorVigilanceTest>[];
  final _results = <PsychomotorVigilanceTestReport>[];

  List<PsychomotorVigilanceTest> getPVTResults() {
    return _psychomotorVigilanceTest;
  }

  List<PsychomotorVigilanceTestReport> getReportData() {
    return _results;
  }

  void add(PsychomotorVigilanceTest psychomotorVigilanceTest) async {
    _psychomotorVigilanceTest.insert(0, psychomotorVigilanceTest);
    await addPVTResult(psychomotorVigilanceTest.toPVTResult());
  }

  Future<void> fetchPVTResults() async {
    final pvtResultsRawData = await firebaseRealTimeDb
        .getEntities(PVTResult.table, PVTResult.fromJson, sortBy: SortBy.DESC);
    _psychomotorVigilanceTest =
        pvtResultsRawData.map((e) => PsychomotorVigilanceTest.fromPVTResult(e)).toList();
  }

  Future<bool> addPVTResult(PVTResult pvtResult) async {
    try {
      await firebaseRealTimeDb.addAutoIdEntity<PVTResult>(pvtResult, PVTResult.table);
    } catch (e) {
      _logger.log(Level.WARNING, e);
      return false;
    }
    return true;
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
      average.generatePVTResultData(psychomotorVigilanceTest);
    }
  }
}
