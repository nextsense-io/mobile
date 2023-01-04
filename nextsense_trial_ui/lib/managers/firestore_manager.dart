import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/managers/firebase_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum Table {
  adhoc_protocols,
  adhoc_surveys,
  data_sessions,
  enrolled_studies,
  events,
  issues,
  organizations,
  questions,
  planned_assessments,
  planned_surveys,
  protocol_surveys,
  scheduled_protocols,
  scheduled_surveys,
  sessions,
  seizures,
  side_effects,
  studies,
  surveys,
  users,
}

extension ParseToString on Table {
  String name() {
    return this.toString().split('.').last;
  }
}

class FirestoreManager {
  static const int _retriesAttemptsNumber = 3;

  final _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final _preferences = getIt<Preferences>();
  late FirebaseFirestore _firestore;
  final CustomLogPrinter _logger = CustomLogPrinter('FirestoreManager');

  Map<Table, CollectionReference> _references = Map();

  FirestoreManager() {
    _firestore = FirebaseFirestore.instanceFor(app: _firebaseApp);
    for (Table table in Table.values) {
      _references[table] = _firestore.collection(table.name());
    }
  }

  FirestoreBatchWriter getFirebaseBatchWriter() {
    return FirestoreBatchWriter(_firestore);
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
        reference = _firestore.collection(tables[i].name()).doc(entityKeys[i]);
      } else {
        reference = reference!.collection(tables[i].name()).doc(entityKeys[i]);
      }
    }
    return reference!;
  }

  Future<FirebaseEntity> addAutoIdReference(List<Table> tables, List<String> entityKeys) async {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? reference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          reference = await _firestore.collection(tables[i].name()).add({});
        } else {
          reference = _firestore.collection(tables[i].name()).doc(entityKeys[i]);
        }
      } else {
        if (i >= entityKeys.length) {
          reference = await reference!.collection(tables[i].name()).add({});
        } else {
          reference = reference!.collection(tables[i].name()).doc(entityKeys[i]);
        }
      }
    }
    return FirebaseEntity(await reference!.get());
  }

  /*
   * Query multiple entities.
   */
  Future<List<FirebaseEntity>?> queryEntities(
      List<Table> tables, List<String> entityKeys, {String? fromCacheWithKey}) async {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? pathReference;
    CollectionReference? collectionReference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          collectionReference = _firestore.collection(tables[i].name());
        } else {
          pathReference = _firestore.collection(tables[i].name()).doc(entityKeys[i]);
        }
      } else {
        if (i >= entityKeys.length) {
          collectionReference = pathReference!.collection(tables[i].name());
        } else {
          pathReference = pathReference!.collection(tables[i].name()).doc(entityKeys[i]);
        }
      }
    }

    QuerySnapshot? snapshot;
    if (fromCacheWithKey != null && _preferences.isCached(fromCacheWithKey)) {
      snapshot = await collectionReference!.get(GetOptions(source: Source.cache));
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
          snapshot = await collectionReference!.get();
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
      // Mark collection as cached, means further 'fromCacheWithKey' requests
      // will get collection from cache
      _preferences.markAsCached(fromCacheWithKey);
    }

    return entities;
  }

  Future<bool> persistEntity(FirebaseEntity entity) async {
    int attemptNumber = 0;
    bool success = false;
    while (!success && attemptNumber < _retriesAttemptsNumber) {
      try {
        await entity
            .getDocumentSnapshot()
            .reference
            .set(entity.getValues());
        success = true;
      } catch (exception) {
        attemptNumber++;
        _logger.log(Level.WARNING, "Failed to persist ${entity.reference}. Message: "
            "${exception.toString()}");
      }
    }
    return success;
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
      _logger.log(Level.WARNING, "Failed to write batch. Message: ${exception}");
      success = false;
    }
    return success;
  }
}