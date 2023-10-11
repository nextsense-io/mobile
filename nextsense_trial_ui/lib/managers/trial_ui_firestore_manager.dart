import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:flutter_common/managers/firestore_manager.dart';

const String dbRootCollectionName = 'online';
const DbVersion dbVersion = DbVersion.v2;

// Database versions in use by the app. Each version has a root collection name in Firestore.
// A value of null means that that version is at the database root for legacy purposes.
enum DbVersion {
  v2('v2');

  final String? documentName;

  const DbVersion(this.documentName);
}

enum Table {
  adhoc_sessions,
  adhoc_surveys,
  data_sessions,
  enrolled_studies,
  events,
  event_types,
  issues,
  organizations,
  questions,
  planned_medications,
  planned_sessions,
  planned_surveys,
  protocol_surveys,
  scheduled_medications,
  scheduled_sessions,
  scheduled_surveys,
  sessions,
  seizures,
  side_effects,
  studies,
  surveys,
  survey_results,
  users,
}

extension ParseToString on Table {
  String name() {
    return this.toString().split('.').last;
  }
}

class TrialUiFirestoreManager extends FirestoreManager {

  TrialUiFirestoreManager() :
        super(rootCollection: dbRootCollectionName, rootDocId: DbVersion.v2.name);

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
  Future<FirebaseEntity?> queryEntity(
      List<Table> tables, List<String> entityKeys, {String? fromCacheWithKey}) async {
    return queryEntityUnchecked(_tablesToStrings(tables), entityKeys);
  }

    /*
   * Construct reference to single entity. The number of entries in the tables list needs to
   * match the entityKeys size.
   *
   * tables: List of tables that makes up the reference, in order. One entityKey
   *         is inserted after each table.
   * entityKeys: List of entity keys for each table in the `tables` parameter.
   */
  DocumentReference getReference(List<Table> tables, List<String> entityKeys) {
    return getReferenceUnchecked(_tablesToStrings(tables), entityKeys);
  }

  Future<DocumentReference> addAutoIdReference(List<Table> tables, List<String> entityKeys) async {
    return addAutoIdReferenceUnchecked(_tablesToStrings(tables), entityKeys);
  }

  /*
   * Add a new entity to the database. The number of entries in the tables list needs to
   * match the entityKeys size.
   *
   * tables: List of tables that makes up the reference, in order. One entityKey
   *         is inserted after each table.
   * entityKeys: List of entity keys for each table in the `tables` parameter.
   */
  Future<FirebaseEntity> addAutoIdEntity(List<Table> tables, List<String> entityKeys) async {
    return addAutoIdEntityUnchecked(_tablesToStrings(tables), entityKeys);
  }

  Future<FirebaseEntity> addEntity(List<Table> tables, List<String> entityKeys) async {
    return addEntityUnchecked(_tablesToStrings(tables), entityKeys);
  }

  /*
   * Query multiple entities.
   */
  Future<List<FirebaseEntity>?> queryEntities(List<Table> tables, List<String> entityKeys,
      {String? fromCacheWithKey, String? orderBy}) async {
    return queryEntitiesUnchecked(_tablesToStrings(tables), entityKeys, orderBy: orderBy);
  }

  CollectionReference? getEntitiesReference(List<Table> tables, List<String> entityKeys) {
    return getEntitiesReferenceUnchecked(_tablesToStrings(tables), entityKeys);
  }

  List<String> _tablesToStrings(List<Table> tables) {
    return tables.map((table) => table.name()).toList();
  }
}