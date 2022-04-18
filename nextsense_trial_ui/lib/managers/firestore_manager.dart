import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/preferences.dart';

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
  scheduled_protocols,
  scheduled_surveys,
  adhoc_protocols,
  adhoc_surveys,
}

extension ParseToString on Table {
  String name() {
    return this.toString().split('.').last;
  }
}

class FirestoreManager {

  final _preferences = getIt<Preferences>();

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
   * fromCacheWithKey: Key in shared preferences which will act as criteria that
   *         entity should be taken from cache.
   */
  Future<FirebaseEntity> queryEntity(
      List<Table> tables, List<String> entityKeys,
      {String? fromCacheWithKey}) async {
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
    Source source = Source.serverAndCache;
    if (fromCacheWithKey != null) {
      if (_preferences.isCached(fromCacheWithKey)) {
        source = Source.cache;
      }
    }
    DocumentSnapshot snapshot =
        await reference!.get(
            GetOptions(source: source
        ));

    if (fromCacheWithKey != null) {
      // Mark doc as cached, means further 'fromCacheWithKey' requests
      // will get doc from cache
      _preferences.markAsCached(fromCacheWithKey);
    }
    return FirebaseEntity(snapshot);
  }

  /*
   * Query multiple entities.
   */
  Future<List<FirebaseEntity>> queryEntities(
      List<Table> tables, List<String> entityKeys,
      {String? fromCacheWithKey}) async {
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

    Source source = Source.serverAndCache;
    if (fromCacheWithKey != null) {
      if (_preferences.isCached(fromCacheWithKey)) {
        source = Source.cache;
      }
    }

    QuerySnapshot snapshot = await collectionReference!.get(
        GetOptions(source: source)
    );
    List<DocumentSnapshot> documents = snapshot.docs;
    List<FirebaseEntity> entities = [];
    for (DocumentSnapshot documentSnapshot in documents) {
      entities.add(FirebaseEntity(documentSnapshot));
    }

    if (fromCacheWithKey != null) {
      // Mark collection as cached, means further 'fromCacheWithKey' requests
      // will get collection from cache
      _preferences.markAsCached(fromCacheWithKey);
    }

    return entities;
  }

  Future persistEntity(FirebaseEntity entity) async {
    entity.getDocumentSnapshot().reference.set(entity.getValues());
  }

}