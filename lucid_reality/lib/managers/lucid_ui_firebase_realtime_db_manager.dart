import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
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

class LucidUiFirebaseRealtimeDBManager {
  final _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final CustomLogPrinter _logger = CustomLogPrinter('FirebaseRealtimeDBManager');
  late FirebaseDatabase _firebaseDatabase;
  late DatabaseReference _lucidDatabase;

  LucidUiFirebaseRealtimeDBManager() {
    _firebaseDatabase = FirebaseDatabase.instanceFor(app: _firebaseApp);
    _firebaseDatabase.setPersistenceEnabled(true);
    _lucidDatabase = _firebaseDatabase.ref(dbRootDBName);
  }

  Future<void> setEntity<T extends FirebaseRealtimeDBEntity>(T entity, String reference) async {
    return _lucidDatabase.child(reference).set(entity.getValues());
  }

  Future<T?> getEntity<T extends FirebaseRealtimeDBEntity>(T entity, String reference) async {
    final snapshot = await _lucidDatabase.child(reference).get();
    if (snapshot.exists) {
      Map<String, dynamic> snapshotValue = Map<String, dynamic>.from(snapshot.value as Map);
      entity.setValues(snapshotValue);
      return entity;
    } else {
      return null;
    }
  }
}
