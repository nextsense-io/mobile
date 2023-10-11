import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/medication/planned_medication.dart';
import 'package:nextsense_trial_ui/domain/medication/scheduled_medication.dart';
import 'package:nextsense_trial_ui/domain/medication/medication.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/trial_ui_firestore_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:flutter_common/utils/android_logger.dart';

class MedicationManager {

  final CustomLogPrinter _logger = CustomLogPrinter('MedicationManager');
  final TrialUiFirestoreManager _firestoreManager = getIt<TrialUiFirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final Preferences _preferences = getIt<Preferences>();

  List<ScheduledMedication> _scheduledMedications = [];
  List<PlannedMedication>? _plannedMedications;

  String get _currentStudyId => _studyManager.currentStudy!.id;

  bool get hasScheduledMedications => _scheduledMedications.isNotEmpty;
  List<PlannedMedication> get plannedMedications => _plannedMedications ?? [];
  List<ScheduledMedication> get scheduledMedications => _scheduledMedications;
  bool get medicationsEnabled => scheduledMedications.isNotEmpty;


  // Load planned medications from study and convert them to scheduled medications that persist in
  // the user table.
  Future<bool> loadPlannedMedications() async {
    final bool? studyScheduled = _studyManager.studyScheduled;
    if (studyScheduled == null) {
      throw("study not initialized. cannot load medications");
    }

    _scheduledMedications.clear();

    bool fromCache = _preferences.getBool(PreferenceKey.studyDataCached);
    _plannedMedications = await _studyManager.loadPlannedMedications(studyScheduled && fromCache);
    if (_plannedMedications == null) {
      return false;
    }

    if (studyScheduled) {
      // If study already scheduled, return scheduled medications from cache if present.
      _logger.log(Level.WARNING, 'Loading scheduled medications from cache');
      List<ScheduledMedication>? scheduledMedications = await _loadScheduledMedications(fromCache);
      if (scheduledMedications != null) {
        _scheduledMedications = scheduledMedications;
      } else {
        return false;
      }
    } else {
      _logger.log(Level.WARNING, 'Creating scheduled medications based on planned medications');
      // Speed up queries by making parallel requests
      List<Future> futures = [];
      for (var plannedMedication in _plannedMedications!) {
        for (var day in plannedMedication.days ?? []) {
          Future future = _firestoreManager.addAutoIdEntity(
              [Table.users, Table.enrolled_studies, Table.scheduled_medications],
              [_authManager.user!.id, _currentStudyId]);
          for (DateTime startTime in plannedMedication.startTimes) {
            future.then((firebaseEntity) {
              // Scheduled medication is created based on planned medication
              ScheduledMedication scheduledMedication = ScheduledMedication.fromStudyDay(
                  firebaseEntity: firebaseEntity, plannedMedication: plannedMedication,
                  studyDay: day, startTime: startTime);

              // Copy period from planned medication
              scheduledMedication.setPeriod(plannedMedication.period);

              if (scheduledMedication.getValue(ScheduledMedicationKey.status) == null) {
                scheduledMedication.setValue(ScheduledMedicationKey.status,
                    MedicationState.before_time.name);
              }

              scheduledMedication.save();
              _scheduledMedications.add(scheduledMedication);
            });
            futures.add(future);
          }
        }
      }
      await Future.wait(futures);
    }

    // Make sure cache is up to date, need to query whole collection
    // Without this query undesired items can appear in cache
    await _queryScheduledMedications();

    // Make consistent order
    _scheduledMedications.sortBy((scheduledMedication) => scheduledMedication.plannedMedicationId);

    return true;
  }

  Future<ScheduledMedication?> queryScheduledMedication(String scheduledMedicationId) async {
    FirebaseEntity? scheduledMedicationEntity = await _firestoreManager.queryEntity(
        [Table.users, Table.enrolled_studies, Table.scheduled_medications],
        [_authManager.user!.id, _currentStudyId, scheduledMedicationId]);
    if (scheduledMedicationEntity != null) {
      final plannedMedicationId = (scheduledMedicationEntity.getValue(
          ScheduledMedicationKey.planned_medication_id) as DocumentReference).id;
      FirebaseEntity? plannedMedicationEntity = await _firestoreManager.queryEntity(
          [Table.studies, Table.planned_medications], [_currentStudyId, plannedMedicationId]);
      if (plannedMedicationEntity != null) {
        PlannedMedication plannedMedication = PlannedMedication(plannedMedicationEntity,
            studyStartDate: _studyManager.currentStudyStartDate!,
            studyEndDate: _studyManager.currentStudyEndDate!);
        return ScheduledMedication(scheduledMedicationEntity, plannedMedication);
      }
    }
    return null;
  }

  Future<bool> takeMedication(ScheduledMedication scheduledMedication) async {
    DateTime now = DateTime.now();
    if (scheduledMedication.isTaken) {
      _logger.log(Level.WARNING, 'Medication already taken');
      return false;
    }
    scheduledMedication.takenDateTime = now;
    if (now.isBefore(scheduledMedication.allowedStartBefore!)) {
      scheduledMedication.setState(MedicationState.taken_early);
    } else if (now.isAfter(scheduledMedication.allowedStartAfter!)) {
      scheduledMedication.setState(MedicationState.taken_late);
    } else {
      scheduledMedication.setState(MedicationState.taken_on_time);
    }
    await scheduledMedication.save();
    return true;
  }

  Future<List<ScheduledMedication>?> _loadScheduledMedications(bool fromCache) async {
    List<FirebaseEntity>? scheduledMedicationEntities =
        await _queryScheduledMedications(fromCache: fromCache);
    if (scheduledMedicationEntities == null) {
      return null;
    }

    if (_plannedMedications == null) {
      return null;
    }

    List<ScheduledMedication> scheduledMedications = [];
    for (FirebaseEntity entity in scheduledMedicationEntities) {
      final plannedMedicationId = entity.getValue(ScheduledMedicationKey.planned_medication_id);
      PlannedMedication? plannedMedication = _plannedMedications!.firstWhereOrNull(
              (plannedMedicationCandidate) => plannedMedicationId == plannedMedicationCandidate.id);

      if (plannedMedication == null) {
        _logger.log(Level.SEVERE, 'Planned medication with id $plannedMedicationId not found');
        continue;
      }

      final scheduledMedication = ScheduledMedication(entity, plannedMedication);
      scheduledMedications.add(scheduledMedication);
    }
    return scheduledMedications;
  }

  Future<List<FirebaseEntity>?> _queryScheduledMedications({bool fromCache = false}) async {
    String cacheKey = "${_currentStudyId}_${Table.scheduled_medications.name()}";
    CollectionReference? collectionReference = _firestoreManager.getEntitiesReference(
        [Table.users, Table.enrolled_studies, Table.scheduled_medications],
        [_authManager.user!.id, _currentStudyId]);
    Query query = collectionReference!.where(ScheduledMedicationKey.schedule_type.name,
        isEqualTo: ScheduleType.scheduled.name);
    return await _firestoreManager.queryCollectionReference(query: query,
        fromCacheWithKey: fromCache ? cacheKey : null);
  }
}
