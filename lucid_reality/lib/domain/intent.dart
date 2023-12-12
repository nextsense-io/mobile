import 'package:flutter_common/domain/firebase_entity.dart';

enum IntentKey {
  id,
  description,
  categoryID,
  realityCheck,
}

class Intent extends FirebaseEntity<IntentKey> {
  Intent(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());
}
