import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseEntity {
  // Snapshot from Firebase to be able to persist or listen to value changes.
  final DocumentSnapshot _documentSnapshot;
  // Current user values. Valid keys are in the UserKey enum.
  final Map<String, dynamic> _values;

  FirebaseEntity(DocumentSnapshot documentSnapshot) :
      this._documentSnapshot = documentSnapshot,
      this._values = documentSnapshot.exists ?
          documentSnapshot.data() as Map<String, dynamic> :
          new Map<String, dynamic>() {}

  DocumentSnapshot getDocumentSnapshot() {
    return _documentSnapshot;
  }

  Map<String, dynamic> getValues() {
    return _values;
  }
}