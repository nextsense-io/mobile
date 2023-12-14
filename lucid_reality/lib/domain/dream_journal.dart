import 'package:flutter_common/domain/firebase_entity.dart';

enum DreamJournalKey {
  id,
  createdAt,
  recordingPath,
  intentionMatchingRating,
  categoryID,
  intentID,
  note,
  title,
  description,
  isLucid,
  recordingDuration,
  tags,
  sketchPath
}

class DreamJournal extends FirebaseEntity<DreamJournalKey> {
  DreamJournal(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());
}
