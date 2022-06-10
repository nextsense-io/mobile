import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/side_effect.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

class SideEffectsManager {
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  Future<bool> addSideEffect(
      {required DateTime startTime,
      DateTime? endTime,
      required List<String> sideEffectTypes,
      required String userNotes}) async {
    FirebaseEntity sideEffectEntity = await _firestoreManager
        .addAutoIdReference([Table.users, Table.side_effects], [_authManager.userCode!]);
    return await _saveSideEffectEntity(
        sideEffectEntity: sideEffectEntity,
        startTime: startTime,
        sideEffectTypes: sideEffectTypes,
        userNotes: userNotes);
  }

  Future<bool> updateSideEffect(
      {required sideEffectId,
      required DateTime startTime,
      DateTime? endTime,
      required List<String> sideEffectTypes,
      required String userNotes}) async {
    FirebaseEntity? sideEffectEntity = await _firestoreManager
        .queryEntity([Table.users, Table.side_effects], [_authManager.userCode!, sideEffectId]);
    if (sideEffectEntity == null) {
      return false;
    }
    return await _saveSideEffectEntity(
        sideEffectEntity: sideEffectEntity,
        startTime: startTime,
        sideEffectTypes: sideEffectTypes,
        userNotes: userNotes);
  }

  Future<bool> deleteSideEffect(SideEffect sideEffect) async {
    return await _firestoreManager.deleteEntity(sideEffect);
  }

  Future<bool> _saveSideEffectEntity(
      {required FirebaseEntity sideEffectEntity,
      required DateTime startTime,
      DateTime? endTime,
      required List<String> sideEffectTypes,
      required String userNotes}) async {
    SideEffect sideEffect = SideEffect(sideEffectEntity);
    sideEffect
      ..setValue(SideEffectKey.start_datetime, startTime)
      ..setValue(SideEffectKey.end_datetime, endTime)
      ..setValue(SideEffectKey.user_notes, userNotes)
      ..setValue(SideEffectKey.side_effect_types, sideEffectTypes);
    bool success = await sideEffect.save();
    if (!success) {
      return false;
    }
    return true;
  }

  Future<List<SideEffect>> getSideEffects() async {
    List<FirebaseEntity>? sideEffectEntities = await _firestoreManager
        .queryEntities([Table.users, Table.side_effects], [_authManager.userCode!]);
    if (sideEffectEntities == null) {
      return [];
    }
    return sideEffectEntities.map((entity) => SideEffect(entity)).toList();
  }
}
