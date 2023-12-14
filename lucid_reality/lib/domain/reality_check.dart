import 'package:flutter_common/domain/firebase_entity.dart';

enum RealityCheckKey {
  id,
  startTime,
  endTime,
  bedTime,
  wakeTime,
  numberOfReminders,
  realityTest,
  createdAt,
  updatedAt,
}

class RealityCheck extends FirebaseEntity<RealityCheckKey> {
  RealityCheck(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());
}
