import 'package:flutter/foundation.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreManager {
  static const int _retriesAttemptsNumber = 3;

  final _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final CustomLogPrinter _logger = CustomLogPrinter('FirestoreManager');
  late FirebaseFirestore _firestore;
  late DocumentReference _rootRef;
  SharedPreferences? _sharedPrefs;
  String? userId;

  FirestoreManager({required String rootCollection, required String rootDocId}) {
    _firestore = FirebaseFirestore.instanceFor(app: _firebaseApp);
    _firestore.settings = const Settings(
        persistenceEnabled: true
    );
    _rootRef = _firestore.collection(rootCollection).doc(rootDocId);
    SharedPreferences.getInstance().then((value) => _sharedPrefs = value);
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
  @protected
  Future<FirebaseEntity?> queryEntityUnchecked(
      List<String> tables, List<String> entityKeys, {String? fromCacheWithKey}) async {
    assert(tables.length == entityKeys.length || tables.length == entityKeys.length + 1);
    DocumentReference reference = getReferenceUnchecked(tables, entityKeys);
    DocumentSnapshot? snapshot;
    if (fromCacheWithKey != null && _isCached(fromCacheWithKey)) {
      try {
        snapshot = await reference.get(const GetOptions(source: Source.cache));
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
      _markAsCached(fromCacheWithKey);
    }

    return FirebaseEntity(snapshot!, this);
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

    return FirebaseEntity(snapshot!, this);
  }

  /*
   * Construct reference to single entity. The number of entries in the tables list needs to
   * match the entityKeys size.
   *
   * tables: List of tables that makes up the reference, in order. One entityKey
   *         is inserted after each table.
   * entityKeys: List of entity keys for each table in the `tables` parameter.
   */
  @protected
  DocumentReference getReferenceUnchecked(List<String> tables, List<String> entityKeys) {
    DocumentReference? reference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        reference = _rootRef.collection(tables[i]).doc(entityKeys[i]);
      } else {
        reference = reference!.collection(tables[i]).doc(entityKeys[i]);
      }
    }
    return reference!;
  }

  @protected
  Future<DocumentReference> addAutoIdReferenceUnchecked(
      List<String> tables, List<String> entityKeys) async {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? reference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          reference = await _rootRef.collection(tables[i]).add({});
        } else {
          reference = _rootRef.collection(tables[i]).doc(entityKeys[i]);
        }
      } else {
        if (i >= entityKeys.length) {
          reference = await reference!.collection(tables[i]).add({});
        } else {
          reference = reference!.collection(tables[i]).doc(entityKeys[i]);
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
  @protected
  Future<FirebaseEntity> addAutoIdEntityUnchecked(
      List<String> tables, List<String> entityKeys) async {
    return FirebaseEntity(await (await addAutoIdReferenceUnchecked(tables, entityKeys)).get(), this);
  }

  @protected
  Future<FirebaseEntity> addEntityUnchecked(List<String> tables, List<String> entityKeys) async {
    assert(tables.length == entityKeys.length);
    DocumentReference? reference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        reference = _firestore.collection(tables[i]).doc(entityKeys[i]);
      } else {
        reference = reference!.collection(tables[i]).doc(entityKeys[i]);
      }
    }
    return FirebaseEntity(await reference!.get(), this);
  }

  /*
   * Query multiple entities.
   */
  @protected
  Future<List<FirebaseEntity>?> queryEntitiesUnchecked(List<String> tables, List<String> entityKeys,
      {String? fromCacheWithKey, String? orderBy}) async {
    CollectionReference? collectionReference = getEntitiesReferenceUnchecked(tables, entityKeys);
    if (collectionReference == null) {
      return null;
    }
    return queryCollectionReference(collectionReference: collectionReference,
        fromCacheWithKey: fromCacheWithKey, orderBy: orderBy);
  }

  @protected
  CollectionReference? getEntitiesReferenceUnchecked(List<String> tables, List<String> entityKeys) {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? pathReference;
    CollectionReference? collectionReference;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          collectionReference = _rootRef.collection(tables[i]);
        } else {
          pathReference = _rootRef.collection(tables[i]).doc(entityKeys[i]);
        }
      } else {
        if (i >= entityKeys.length) {
          collectionReference = pathReference!.collection(tables[i]);
        } else {
          pathReference = pathReference!.collection(tables[i]).doc(entityKeys[i]);
        }
      }
    }
    return collectionReference;
  }

  Future<List<FirebaseEntity>?> queryCollectionReference({CollectionReference? collectionReference,
    Query? query, String? fromCacheWithKey, String? orderBy}) async {
    QuerySnapshot? snapshot;
    if (fromCacheWithKey != null && _isCached(fromCacheWithKey)) {
      if (query != null) {
        snapshot = await query.get(const GetOptions(source: Source.cache));
      } else {
        snapshot = await collectionReference!.get(const GetOptions(source: Source.cache));
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
      entities.add(FirebaseEntity(documentSnapshot, this));
    }

    if (fromCacheWithKey != null && snapshot.size > 0) {
      // Mark collection as cached so further 'fromCacheWithKey' requests will get the collection
      // from the cache.
      _markAsCached(fromCacheWithKey);
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

  // Determines that entity specified by 'key' is cached
  bool _isCached(String key) {
    return _sharedPrefs?.getBool(key) ?? false;
  }

  // Mark entity specified by 'key' as cached
  void _markAsCached(String key) {
    _sharedPrefs?.setBool(key, true);
  }
}

// Automatically create multiple batches for writing new entities and commit them. This can be used
// to speedup creating multiple entities.
class FirestoreBatchWriter {

  static const int _firestoreMaximumBatchSize = 500;

  final FirebaseFirestore _firestore;
  final CustomLogPrinter _logger = CustomLogPrinter('FirestoreBatchWriter');
  final List<WriteBatch> _batchList = [];
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