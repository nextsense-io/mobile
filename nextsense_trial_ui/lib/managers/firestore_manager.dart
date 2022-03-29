import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

enum Table {
  organizations,
  users,
  sessions,
  data_sessions,
  planned_assessments,
  planned_surveys,
  studies,
  surveys,
  questions,
  scheduled_protocols
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

  /*
   * Query a single entity. The number of entries in the tables list needs to
   * match the entityKeys size.
   *
   * tables: List of tables that makes up the reference, in order. One entityKey
   *         is inserted after each table.
   * entityKeys: List of entity keys for each table in the `tables` parameter.
   */
  Future<FirebaseEntity> queryEntity(
      List<Table> tables, List<String> entityKeys) async {
    assert(tables.length == entityKeys.length);
    DocumentReference? reference = null;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        reference = FirebaseFirestore.instance.collection(tables[i].name()).doc(
            entityKeys[i]);
      } else {
        reference = reference!.collection(tables[i].name()).doc(
            entityKeys[i]);
      }
    }
    DocumentSnapshot snapshot = await reference!.get();
    return FirebaseEntity(snapshot);
  }

  /*
   * Query multiple entities.
   */
  Future<List<FirebaseEntity>> queryEntities(
      List<Table> tables, List<String> entityKeys) async {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? pathReference = null;
    CollectionReference? collectionReference = null;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          collectionReference = FirebaseFirestore.instance.collection(
              tables[i].name());
        } else {
          pathReference = FirebaseFirestore.instance.collection(
              tables[i].name()).doc(entityKeys[i]);
        }
      } else {
        if (i >= entityKeys.length) {
          collectionReference = pathReference!.collection(tables[i].name());
        } else {
          pathReference = pathReference!.collection(tables[i].name()).doc(
              entityKeys[i]);
        }
      }
    }

    List<DocumentSnapshot> documents = (await collectionReference!.get()).docs;
    List<FirebaseEntity> entities = [];
    for (DocumentSnapshot documentSnapshot in documents) {
      entities.add(FirebaseEntity(documentSnapshot));
    }
    return entities;
  }

  Future persistEntity(FirebaseEntity entity) async {
    entity.getDocumentSnapshot().reference.set(entity.getValues());
  }


}