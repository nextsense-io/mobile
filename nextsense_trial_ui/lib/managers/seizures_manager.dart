import 'package:nextsense_trial_ui/di.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/trail_ui_firestore_manager.dart';

class SeizuresManager {
  final TrialUiFirestoreManager _firestoreManager = getIt<TrialUiFirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  Future<bool> addSeizure({required DateTime startTime, DateTime? endTime,
    required List<String> triggers, required String userNotes}) async {
    FirebaseEntity seizureEntity = await _firestoreManager.addAutoIdEntity(
        [Table.users, Table.seizures], [_authManager.user!.id]);
    return await _saveSeizureEntity(seizureEntity: seizureEntity, startTime: startTime,
        triggers: triggers, userNotes: userNotes);
  }

  Future<bool> updateSeizure({required seizureId, required DateTime startTime, DateTime? endTime,
    required List<String> triggers, required String userNotes}) async {
    FirebaseEntity? seizureEntity = await _firestoreManager.queryEntity(
        [Table.users, Table.seizures], [_authManager.user!.id, seizureId]);
    if (seizureEntity == null) {
      return false;
    }
    return await _saveSeizureEntity(seizureEntity: seizureEntity, startTime: startTime,
        triggers: triggers, userNotes: userNotes);
  }

  Future<bool> deleteSeizure(Seizure seizure) async {
    return await _firestoreManager.deleteEntity(seizure);
  }

  Future<bool> _saveSeizureEntity({required FirebaseEntity seizureEntity,
      required DateTime startTime, DateTime? endTime, required List<String> triggers,
      required String userNotes}) async {
    Seizure seizure = Seizure(seizureEntity);
    seizure..setValue(
        SeizureKey.start_datetime, startTime)
      ..setValue(SeizureKey.end_datetime, endTime)
      ..setValue(SeizureKey.user_notes, userNotes)
      ..setValue(SeizureKey.triggers, triggers);
    bool success = await seizure.save();
    if (!success) {
      return false;
    }
    return true;
  }

  Future<List<Seizure>> getSeizures() async {
    List<FirebaseEntity>? seizureEntities = await _firestoreManager.queryEntities(
        [Table.users, Table.seizures], [_authManager.user!.id]);
    if (seizureEntities == null) {
      return [];
    }
    return seizureEntities.map((entity) => Seizure(entity)).toList();
  }
}