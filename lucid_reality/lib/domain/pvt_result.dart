import 'package:flutter_common/domain/firebase_entity.dart';

enum PVTResultKey {
  id,
  createdAt,
  reactions,
  avg,
}

class PVTResult extends FirebaseEntity<PVTResultKey> {
  PVTResult(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());
}
