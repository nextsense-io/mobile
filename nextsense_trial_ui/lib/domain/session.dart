import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum SessionKey {
  // Configuration name of the device's channels. Used to map the channel
  // indexes to electrode locations.
  channel_config,
  // Id of the NextSense device that was used to record the session.
  device_id,
  // Id of the earbuds that were plugged in the NextSense device to record the
  // session.
  earbud_id,
  // End of the recording session.
  end_datetime,
  // Firmware version of the NextSense device used to record the session.
  fw_version,
  // Generic notes on the session.
  notes,
  // `organization_id` of the clinical location where this was recorded or who
  // coordinated the recording.
  recorded_at,
  // Start of the recording session.
  start_datetime,
  // `study_id` in which this session was recorded.
  study_id,
  // `user_id` of who recorded this session.
  user_id
}

class Session extends FirebaseEntity {

  Session(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  dynamic getValue(SessionKey sessionKey) {
    return getValues()[sessionKey.name];
  }

  void setValue(SessionKey sessionKey, dynamic value) {
    getValues()[sessionKey.name] = value;
  }
}