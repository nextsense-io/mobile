import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseEntity<T extends Enum> {
  // Snapshot from Firebase to be able to persist or listen to value changes.
  final DocumentSnapshot _documentSnapshot;
  // Current user values. Valid keys are in the UserKey enum.
  final Map<String, dynamic> _values;

  // Id of entity
  String get id => _documentSnapshot.id;

  DocumentReference get reference => _documentSnapshot.reference;

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

  dynamic getValue(T enumKey) {
    return getValues()[enumKey.name];
  }

  void setValue(T enumKey, dynamic value) {
    getValues()[enumKey.name] = value;
  }

  @override
  String toString() {
    final type = this.runtimeType.toString();
    return "$type($id) [${getValues()}]";
  }
}