import 'package:flutter_common/domain/firebase_entity.dart';

/// Each entry corresponds to a field name in the database instance.
enum DataSessionKey {
  // Name of the data session. Used to identify
  name,
  // End of the recording data session.
  end_datetime,
  // Start of the recording data session.
  start_datetime,
  // Effective sampling rate at which the data was transmitted over Bluetooth and saved in the
  // database.
  streaming_rate,
}

class DataSession extends FirebaseEntity<DataSessionKey> {

  DataSession(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());

}