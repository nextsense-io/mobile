import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/managers/firebase_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

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

// Database versions in use by the app. Each version has a root collection name in Firestore.
// A value of null means that that version is at the database root for legacy purposes.
enum DbVersion {
  v2('v2');

  final String? documentName;

  const DbVersion(this.documentName);
}

extension ParseToString on Table {
  String name() {
    return this.toString().split('.').last;
  }
}

class FirestoreManager {
  static const int _retriesAttemptsNumber = 3;
  static const String _dbRootCollectionName = 'online';
  static const DbVersion _dbVersion = DbVersion.v2;

  final _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final _preferences = getIt<Preferences>();
  final CustomLogPrinter _logger = CustomLogPrinter('FirestoreManager');
  late FirebaseFirestore _firestore;
  late DocumentReference _rootRef;
  String? userId;

  FirestoreManager() {
    _firestore = FirebaseFirestore.instanceFor(app: _firebaseApp);
    _firestore.settings = const Settings(
      persistenceEnabled: true
    );
    _rootRef = _firestore.collection(_dbRootCollectionName).doc(_dbVersion.documentName);
  }

  FirestoreBatchWriter getFirebaseBatchWriter() {
    return FirestoreBatchWriter(_firestore);
  }

  // Sets the user id so that when entities are updated the user id is set in 'updated_by'.
  setUserId(String userId) {
    this.userId = userId;
  }

  String? getUserId() {
    return userId;
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
  Future<FirebaseEntity?> queryEntity(
      List<Table> tables, List<String> entityKeys, {String? fromCacheWithKey}) async {
    assert(tables.length == entityKeys.length || tables.length == entityKeys.length + 1);
    DocumentReference reference = getReference(tables, entityKeys);
    DocumentSnapshot? snapshot;
    if (fromCacheWithKey != null && _preferences.isCached(fromCacheWithKey)) {
        try {
          snapshot = await reference.get(GetOptions(source: Source.cache));
          _logger.log(Level.WARNING, 'Loaded document "$fromCacheWithKey" from cache');
        } on FirebaseException {
          // Fallback to server
          snapshot = null;
        }
    }

    // Get document from server
    if (snapshot == null) {
      int attemptNumber = 0;
      bool success = false;
      while (!success && attemptNumber < _retriesAttemptsNumber) {
        try {
          snapshot = await reference.get();
          success = true;
        } catch (exception) {
          attemptNumber++;
          _logger.log(Level.WARNING, "Failed to query. Message: ${exception.toString()}");
        }
      }
      if (!success) {
        return null;
      }
    }

    // Mark doc as cached, means further 'fromCacheWithKey' requests will get doc from cache.
    if (fromCacheWithKey != null && snapshot!.exists) {
      _preferences.markAsCached(fromCacheWithKey);
    }

    return FirebaseEntity(snapshot!);
  }

  /*
   * Query a single entity by its complete reference path.
   *
   * documentPath: Complete document path to the entity.
   */
  Future<FirebaseEntity?> queryReference(String documentPath) async {
    DocumentReference? reference = _firestore.doc(documentPath);

    DocumentSnapshot? snapshot;
    int attemptNumber = 0;
    bool success = false;
    while (!success && attemptNumber < _retriesAttemptsNumber) {
      try {
        snapshot = await reference.get();
        success = true;
      } catch (exception) {
        attemptNumber++;
        _logger.log(Level.WARNING, "Failed to query. Message: ${exception.toString()}");
      }
    }
    if (!success) {
      return null;
    }

    return FirebaseEntity(snapshot!);
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
    DocumentReference? reference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        reference = _rootRef.collection(tables[i].name()).doc(entityKeys[i]);
      } else {
        reference = reference!.collection(tables[i].name()).doc(entityKeys[i]);
      }
    }
    return reference!;
  }

  Future<DocumentReference> addAutoIdReference(List<Table> tables, List<String> entityKeys) async {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? reference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          reference = await _rootRef.collection(tables[i].name()).add({});
        } else {
          reference = _rootRef.collection(tables[i].name()).doc(entityKeys[i]);
        }
      } else {
        if (i >= entityKeys.length) {
          reference = await reference!.collection(tables[i].name()).add({});
        } else {
          reference = reference!.collection(tables[i].name()).doc(entityKeys[i]);
        }
      }
    }
    return reference!;
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
    return FirebaseEntity(await (await addAutoIdReference(tables, entityKeys)).get());
  }

  Future<FirebaseEntity> addEntity(List<Table> tables, List<String> entityKeys) async {
    assert(tables.length == entityKeys.length);
    DocumentReference? reference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        reference = _firestore.collection(tables[i].name()).doc(entityKeys[i]);
      } else {
        reference = reference!.collection(tables[i].name()).doc(entityKeys[i]);
      }
    }
    return FirebaseEntity(await reference!.get());
  }

  /*
   * Query multiple entities.
   */
  Future<List<FirebaseEntity>?> queryEntities(
      List<Table> tables, List<String> entityKeys,
      {String? fromCacheWithKey, String? orderBy}) async {
    CollectionReference? collectionReference = getEntitiesReference(tables, entityKeys);
    if (collectionReference == null) {
      return null;
    }
    return queryCollectionReference(collectionReference: collectionReference,
        fromCacheWithKey: fromCacheWithKey, orderBy: orderBy);
  }

  CollectionReference? getEntitiesReference(List<Table> tables, List<String> entityKeys) {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? pathReference;
    CollectionReference? collectionReference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          collectionReference = _rootRef.collection(tables[i].name());
        } else {
          pathReference = _rootRef.collection(tables[i].name()).doc(entityKeys[i]);
        }
      } else {
        if (i >= entityKeys.length) {
          collectionReference = pathReference!.collection(tables[i].name());
        } else {
          pathReference = pathReference!.collection(tables[i].name()).doc(entityKeys[i]);
        }
      }
    }
    return collectionReference;
  }

  Future<List<FirebaseEntity>?> queryCollectionReference({CollectionReference? collectionReference,
      Query? query, String? fromCacheWithKey, String? orderBy}) async {
    QuerySnapshot? snapshot;
    if (fromCacheWithKey != null && _preferences.isCached(fromCacheWithKey)) {
      if (query != null) {
        snapshot = await query.get(GetOptions(source: Source.cache));
      } else {
        snapshot = await collectionReference!.get(GetOptions(source: Source.cache));
      }
      if (snapshot.size == 0) {
        _logger.log(Level.WARNING,
            'Empty cached collection "$fromCacheWithKey", fallback to server');
        snapshot = null;
      }
    }

    if (snapshot == null) {
      // Get snapshot from server
      int attemptNumber = 0;
      bool success = false;
      while (!success && attemptNumber < _retriesAttemptsNumber) {
        try {
          if (query != null && orderBy != null) {
            query = query.orderBy(orderBy);
          }
          if (query != null) {
            snapshot = await query.get();
          } else {
            snapshot = await collectionReference!.get();
          }
          success = true;
        } catch (exception) {
          attemptNumber++;
          _logger.log(Level.WARNING, "Failed to query. Message: ${exception.toString()}");
        }
      }
      if (!success) {
        return null;
      }
    }

    List<DocumentSnapshot> documents = snapshot!.docs;
    List<FirebaseEntity> entities = [];
    for (DocumentSnapshot documentSnapshot in documents) {
      entities.add(FirebaseEntity(documentSnapshot));
    }

    if (fromCacheWithKey != null && snapshot.size > 0) {
      // Mark collection as cached so further 'fromCacheWithKey' requests will get the collection
      // from the cache.
      _preferences.markAsCached(fromCacheWithKey);
    }

    return entities;
  }

  Future<bool> persistEntity<T extends Enum>(FirebaseEntity<T> entity) async {
    if (entity.getDocumentSnapshot().exists) {
      entity
          .getDocumentSnapshot()
          .reference
          .update(entity.getValues());
    } else {
      entity
          .getDocumentSnapshot()
          .reference
          .set(entity.getValues());
    }
    return true;
  }

  Future<bool> deleteEntity(FirebaseEntity entity) async {
    int attemptNumber = 0;
    bool success = false;
    while (!success && attemptNumber < _retriesAttemptsNumber) {
      try {
        await entity.getDocumentSnapshot().reference.delete();
        success = true;
      } catch (exception) {
        attemptNumber++;
        _logger.log(Level.WARNING, "Failed to delete ${entity.reference}. Message: "
            "${exception.toString()}");
      }
    }
    return success;
  }
}

// Automatically create multiple batches for writing new entities and commit them. This can be used
// to speedup creating multiple entities.
class FirestoreBatchWriter {

  static const int _firestoreMaximumBatchSize = 500;

  final FirebaseFirestore _firestore;
  final CustomLogPrinter _logger = CustomLogPrinter('FirestoreBatchWriter');
  List<WriteBatch> _batchList = [];
  WriteBatch? _currentBatch;
  int _indexInCurrentBatch = 0;

  int get numberOfBatches => _batchList.length;

  FirestoreBatchWriter(this._firestore);

  // Add entity to batch, when index of adding entity firestoreMaximumBatchSize.
  void add(DocumentReference ref, Map<String, dynamic> entityFields) {
    if (_indexInCurrentBatch == 0) {
      _currentBatch = _firestore.batch();
      _batchList.add(_currentBatch!);
    }
    _currentBatch!.set(ref, entityFields);
    _indexInCurrentBatch = (_indexInCurrentBatch + 1) % _firestoreMaximumBatchSize;
  }

  // Commit all constructed batches.
  Future<bool> commitAll() async {
    bool success = true;
    try {
      await Future.wait(_batchList.map((batch) {
        return batch.commit();
      }));
    } catch (exception) {
      _logger.log(Level.WARNING, "Failed to write batch. Message: $exception");
      success = false;
    }
    return success;
  }
}