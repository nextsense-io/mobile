import 'package:flutter/foundation.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/dream_journal.dart';
import 'package:lucid_reality/domain/intent_entity.dart';
import 'package:lucid_reality/domain/reality_check_entity.dart';
import 'package:lucid_reality/domain/reality_test.dart';
import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';

class LucidManager {
  final _logger = CustomLogPrinter('LucidManager');
  final firebaseRealTimeDb = getIt<LucidUiFirebaseRealtimeDBManager>();
  final IntentEntity intentEntity = IntentEntity.instance;
  final RealityCheckEntity realityCheck = RealityCheckEntity.instance;
  final ValueNotifier<String> newDreamJournalCreatedNotifier = ValueNotifier('');
  final ValueNotifier<int> realityCheckingNotifier = ValueNotifier(0);

  Future<void> fetchIntent() async {
    await firebaseRealTimeDb.getEntityAs<IntentEntity>(
        IntentEntity.table.where('${firebaseRealTimeDb.getUserId()}'), IntentEntity.fromJson);
  }

  Future<void> fetchRealityCheck() async {
    await firebaseRealTimeDb.getEntityAs<RealityCheckEntity>(
        RealityCheckEntity.table.where('${intentEntity.entityId}'), RealityCheckEntity.fromJson);
  }

  Future<void> _updateIntent() async {
    firebaseRealTimeDb.setEntity(
        intentEntity,
        IntentEntity.table
            .where('${firebaseRealTimeDb.getUserId()}')
            .and()
            .where('${intentEntity.entityId}'));
  }

  Future<bool> _addIntent() async {
    try {
      intentEntity.setCreatedAt(DateTime.now());
      await firebaseRealTimeDb.addAutoIdEntity<IntentEntity>(intentEntity, IntentEntity.table);
    } catch (e) {
      _logger.log(Level.WARNING, e);
      return false;
    }
    return true;
  }

  Future<bool> _saveRealityCheck() async {
    try {
      String intentEntityId = intentEntity.entityId ?? '';
      realityCheck.setId(intentEntityId);
      await firebaseRealTimeDb.setEntity<RealityCheckEntity>(
          realityCheck, RealityCheckEntity.table.where(intentEntityId));
    } catch (e) {
      _logger.log(Level.WARNING, e);
      return false;
    }
    return true;
  }

  Future<void> saveNumberOfReminders(
      {required int startTime, required int endTime, required int numberOfReminders}) async {
    realityCheck.setNumberOfReminders(numberOfReminders);
    realityCheck.setStartTime(startTime);
    realityCheck.setEndTime(endTime);
    await _saveRealityCheck();
  }

  Future<void> saveRealityCheckTimes(int startTime, int endTime) async {
    realityCheck.setStartTime(startTime);
    realityCheck.setEndTime(endTime);
    await _saveRealityCheck();
  }

  Future<void> saveBedtime(int bedtime, int wakeUpTime) async {
    realityCheck.setBedTime(bedtime);
    realityCheck.setWakeTime(wakeUpTime);
    await _saveRealityCheck();
    realityCheckingNotifier.value = DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> saveRealityTest(RealityTest realityTest) async {
    realityCheck.setRealityTest(realityTest);
    await _saveRealityCheck();
  }

  Future<void> updateCategoryId(String categoryId) async {
    intentEntity.setCategoryID(categoryId);
    intentEntity.setUpdatedAt(DateTime.now());
    // If entry id null that mean we don't have any record yet in db, so we have have to create new record.
    if (intentEntity.entityId == null) {
      await _addIntent();
      // now we have to update table id.
      intentEntity.setId(intentEntity.entityId);
      await _updateIntent();
    } else {
      intentEntity.setId(intentEntity.entityId);
      await _updateIntent();
    }
  }

  Future<void> updateDescription(String description) async {
    intentEntity.setDescription(description);
    intentEntity.setUpdatedAt(DateTime.now());
    await _updateIntent();
  }

  Future<bool> saveDreamJournalRecord(DreamJournal dreamJournal) async {
    try {
      await firebaseRealTimeDb.addAutoIdEntity<DreamJournal>(dreamJournal, DreamJournal.table);
      newDreamJournalCreatedNotifier.value = dreamJournal.getId() ?? '';
    } catch (e) {
      _logger.log(Level.WARNING, e);
      return false;
    }
    return true;
  }

  Future<List<DreamJournal>> fetchDreamJournals() async {
    return await firebaseRealTimeDb.getEntities(
      DreamJournal.table,
      DreamJournal.fromJson,
      sortBy: SortBy.DESC,
    );
  }

  Future<bool> deleteDreamJournal(DreamJournal dreamJournal) async {
    return await firebaseRealTimeDb.deleteEntity(
      DreamJournal.table
          .where(firebaseRealTimeDb.getUserId() ?? '')
          .and()
          .where(dreamJournal.getId() ?? ''),
    );
  }

  Future<void> updateDreamJournalRecord(DreamJournal dreamJournal) async {
    await firebaseRealTimeDb.setEntity(
      dreamJournal,
      DreamJournal.table
          .where(firebaseRealTimeDb.getUserId() ?? '')
          .and()
          .where(dreamJournal.getId() ?? ''),
    );
    newDreamJournalCreatedNotifier.value = dreamJournal.getId() ?? '';
  }
}
