import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum DataSessionKey {
  // End of the recording data session.
  end_datetime,
  // Start of the recording data session.
  start_datetime,
  // Effective sampling rate at which the data was transmitted over Bluetooth
  // and saved in the database.
  streaming_rate,
}

class DataSession extends FirebaseEntity {

  DataSession(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  dynamic getValue(DataSessionKey dataSessionKey) {
    return getValues()[dataSessionKey.name];
  }

  void setValue(DataSessionKey dataSessionKey, dynamic value) {
    getValues()[dataSessionKey.name] = value;
  }
}