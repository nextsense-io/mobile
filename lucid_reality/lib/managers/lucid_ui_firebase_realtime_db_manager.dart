import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';

const String dbRootDBName = 'LucidReality';

enum Table {
  acknowledgements,
  brainChecks,
  categories,
  intents,
  journals,
  realityChecks,
  users,
}

extension ParseToString on Table {
  String name() {
    return toString().split('.').last;
  }
}

extension SnapshotToMap on DataSnapshot {
  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(value as Map);
  }
}

class LucidUiFirebaseRealtimeDBManager {
  final _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final CustomLogPrinter _logger = CustomLogPrinter('FirebaseRealtimeDBManager');
  late FirebaseDatabase _firebaseDatabase;
  late DatabaseReference _lucidDatabase;
  String? userId;

  LucidUiFirebaseRealtimeDBManager() {
    _firebaseDatabase = FirebaseDatabase.instanceFor(app: _firebaseApp);
    _firebaseDatabase.setPersistenceEnabled(true);
    _lucidDatabase = _firebaseDatabase.ref(dbRootDBName);
  }

  setUserId(String userId) {
    this.userId = userId;
  }

  String? getUserId() {
    return userId;
  }

  Future<void> updateEntity<T extends FirebaseRealtimeDBEntity>(T entity, String reference) async {
    return _lucidDatabase.child('$reference/$userId').update(entity.getValues());
  }

  Future<void> setEntity<T extends FirebaseRealtimeDBEntity>(T entity, String reference) async {
    return _lucidDatabase.child(reference).set(entity.getValues());
  }

  Future<T?> getEntity<T extends FirebaseRealtimeDBEntity>(T entity, String reference) async {
    final snapshot = await _lucidDatabase.child(reference).get();
    if (snapshot.exists) {
      Map<String, dynamic> snapshotValue = snapshot.toMap();
      entity.setValues(snapshotValue);
      return entity;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>> getEntities(String reference) async {
    final snapshot = await _lucidDatabase.child('$reference/$userId').get();
    _logger.log(Level.INFO, 'request =>$reference/$userId, fetch result->${snapshot.value}');
    if (snapshot.exists) {
      return snapshot.toMap();
    }
    return <String, dynamic>{};
  }

  Future<void> addAutoIdEntity<T extends FirebaseRealtimeDBEntity>(
      T entity, String reference) async {
    _lucidDatabase.child('$reference/$userId').push().set(entity.toJson());
  }
}
