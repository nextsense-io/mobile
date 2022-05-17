import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum Table {
  adhoc_protocols,
  adhoc_surveys,
  data_sessions,
  enrolled_studies,
  events,
  organizations,
  questions,
  planned_assessments,
  planned_surveys,
  scheduled_protocols,
  scheduled_surveys,
  sessions,
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

  final CustomLogPrinter _logger = CustomLogPrinter('FirestoreManager');
  final _preferences = getIt<Preferences>();

  Map<Table, CollectionReference> _references = Map();

  FirestoreManager() {
    for (Table table in Table.values) {
      _references[table] = FirebaseFirestore.instance.collection(table.name());
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
  Future<FirebaseEntity?> queryEntity(
      List<Table> tables, List<String> entityKeys,
      {String? fromCacheWithKey}) async {
    assert(tables.length == entityKeys.length);
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
   * Construct reference to single entity. The number of entries in the tables list needs to
   * match the entityKeys size.
   *
   * tables: List of tables that makes up the reference, in order. One entityKey
   *         is inserted after each table.
   * entityKeys: List of entity keys for each table in the `tables` parameter.
   */
  DocumentReference getReference(List<Table> tables, List<String> entityKeys) {
    DocumentReference? reference = null;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        reference = FirebaseFirestore.instance.collection(tables[i].name()).doc(entityKeys[i]);
      } else {
        reference = reference!.collection(tables[i].name()).doc(entityKeys[i]);
      }
    }
    return reference!;
  }

  /*
   * Query multiple entities.
   */
  Future<List<FirebaseEntity>?> queryEntities(
      List<Table> tables, List<String> entityKeys,
      {String? fromCacheWithKey}) async {
    assert(tables.length == entityKeys.length + 1);
    DocumentReference? pathReference = null;
    CollectionReference? collectionReference = null;
    for (int i = 0; i < tables.length; ++i) {
      if (i == 0) {
        if (entityKeys.isEmpty) {
          collectionReference = FirebaseFirestore.instance.collection(tables[i].name());
        } else {
          pathReference = FirebaseFirestore.instance.collection(
              tables[i].name()).doc(entityKeys[i]);
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
      snapshot = await collectionReference!.get(
          GetOptions(source: Source.cache));
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
        _logger.log(Level.WARNING, "Failed to persist ${entity.reference}. Message: "
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

  final CustomLogPrinter _logger = CustomLogPrinter('FirestoreBatchWriter');
  List<WriteBatch> _batchList = [];
  WriteBatch? _currentBatch;
  int _indexInCurrentBatch = 0;

  int get numberOfBatches => _batchList.length;

  // Add entity to batch, when index of adding entity firestoreMaximumBatchSize.
  void add(DocumentReference ref, Map<String, dynamic> entityFields) {
    if (_indexInCurrentBatch == 0) {
      _currentBatch = FirebaseFirestore.instance.batch();
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