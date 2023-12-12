import 'package:flutter_common/domain/firebase_entity.dart';

enum RealityTestKey {
  name,
  description,
  totemSound,
  type,
}

class RealityTest extends FirebaseEntity<RealityTestKey> {
  RealityTest(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());
}
