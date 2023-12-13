import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/domain/pvt_result.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';

class PVTManager {
  final _logger = CustomLogPrinter('PVTManager');
  final firebaseRealTimeDb = getIt<LucidUiFirebaseRealtimeDBManager>();
  List<PsychomotorVigilanceTest> _psychomotorVigilanceTest = <PsychomotorVigilanceTest>[];

  List<PsychomotorVigilanceTest> getPVTResults() {
    return _psychomotorVigilanceTest;
  }

  Future<void> fetchPVTResults() async {
    final pvtResultsRawData = await firebaseRealTimeDb.getEntities(PVTResult.table);
    _psychomotorVigilanceTest = pvtResultsRawData.entries
        .map((e) => PsychomotorVigilanceTest.fromPVTResult(PVTResult.fromJson(e)))
        .toList();
    _logger.log(Level.INFO, "PvtResults$pvtResultsRawData");
    _logger.log(Level.INFO, "PvtResults$_psychomotorVigilanceTest");
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
}
