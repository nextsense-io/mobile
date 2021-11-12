import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

enum Table {
  organizations,
  users,
  sessions,
  studies,
  surveys
}

extension ParseToString on Table {
  String name() {
    return this.toString().split('.').last;
  }
}

class FirestoreManager {
  Map<Table, CollectionReference> _references = Map();

  FirestoreManager() {
    for (Table table in Table.values) {
      _references[table] =
          FirebaseFirestore.instance.collection(table.name());
    }
  }

  Future<FirebaseEntity?> queryEntity(Table table, String entityKey) async {
    DocumentSnapshot snapshot = await _references[table]!.doc(entityKey).get();
    print(snapshot);
    if (!snapshot.exists) {
      return null;
    }
    return FirebaseEntity(snapshot);
  }

  Future persistEntity(FirebaseEntity entity) async {
    entity.getDocumentSnapshot().reference.set(entity.getValues());
  }
}