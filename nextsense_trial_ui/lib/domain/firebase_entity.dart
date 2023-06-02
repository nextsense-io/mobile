import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

enum BaseEntityKey {
  // User id of the user who created this record.
  created_by,
  // Datetime when this record was created.
  created_at,
  // User id of the user who last updated this record.
  updated_by,
  // Datetime when this record was last updated.
  updated_at,
}

class FirebaseEntity<T extends Enum> {

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  // Snapshot from Firebase to be able to persist or listen to value changes.
  final DocumentSnapshot _documentSnapshot;
  final bool _addMonitoringFields;
  // Current user values. Valid keys are in the UserKey enum.
  final Map<String, dynamic> _values;

  // Id of entity.
  String get id => _documentSnapshot.id;
  DateTime get createdAt => (_values[BaseEntityKey.created_at] as Timestamp).toDate();
  String get createdBy => _values[BaseEntityKey.created_by];
  DateTime get updatedAt => (_values[BaseEntityKey.updated_at] as Timestamp).toDate();
  String get updatedBy => _values[BaseEntityKey.updated_by];

  DocumentReference get reference => _documentSnapshot.reference;

  FirebaseEntity(DocumentSnapshot documentSnapshot, {bool addMonitoringFields = true}) :
      _documentSnapshot = documentSnapshot,
      _addMonitoringFields = addMonitoringFields,
      _values = documentSnapshot.exists ?
          documentSnapshot.data() as Map<String, dynamic> :
          new Map<String, dynamic>() {}

  DocumentSnapshot getDocumentSnapshot() {
    return _documentSnapshot;
  }

  Map<String, dynamic> getValues() {
    return _values;
  }

  setValues(Map<String, dynamic> values) {
    _values.clear();
    _values.addAll(values);
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

  // Save entity to Firestore.
  Future<bool> save() async {
    final now = Timestamp.now();
    String? userId = _firestoreManager.getUserId();
    if (userId == null || userId.isEmpty) {
      return false;
    }
    if (_addMonitoringFields) {
      if (getValues()[BaseEntityKey.created_at.name] == null) {
        getValues()[BaseEntityKey.created_at.name] = now;
        getValues()[BaseEntityKey.created_by.name] = userId;
      }
      getValues()[BaseEntityKey.updated_at.name] = now;
      getValues()[BaseEntityKey.updated_by.name] = userId;
    }
    return await _firestoreManager.persistEntity(this);
  }
}