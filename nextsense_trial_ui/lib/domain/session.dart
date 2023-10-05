import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_common/domain/firebase_entity.dart';

/// Each entry corresponds to a field name in the database instance.
enum SessionKey {
  // Configuration name of the device's channels. Used to map the channel
  // indexes to electrode locations.
  channel_config,
  // Id of the NextSense device that was used to record the session.
  device_id,
  // Firmware version of the NextSense device that was used to record the session.
  device_firmware_version,
  // BLE mac address of the NextSense device that was used to record the session.
  device_mac_address,
  // Id of the earbuds that were plugged in the NextSense device to record the
  // session.
  earbud_id,
  // Configuration name of the earbuds. Used to map the earbud indexes to ear locations.
  earbud_config,
  // End of the recording session.
  end_datetime,
  // Mobile app version of the NextSense app used to record the session.
  mobile_app_version,
  // Generic notes on the session.
  notes,
  // `planned_session_id` of the planned session of this session.
  planned_session_id,
  // Name of the protocol that was ran to record this session
  protocol_name,
  // Map of protocol specific information that was recorded from the user that is not parts of
  // of the standard events.
  protocol_data,
  // `organization_id` of the clinical location where this was recorded or who
  // coordinated the recording.
  recorded_at,
  // `scheduled_session_id` of the scheduled session of this session.
  scheduled_session_id,
  // Start of the recording session.
  start_datetime,
  // `study_id` in which this session was recorded.
  study_id,
  // Local timezone when the session was recorded.
  timezone,
  // `user_id` of who recorded this session.
  user_id,
}

class Session extends FirebaseEntity<SessionKey> {

  Session(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());

  DateTime? getStartDateTime() {
    final Timestamp? startDateTime = getValue(SessionKey.start_datetime);
    return startDateTime != null ? startDateTime.toDate() : null;
  }
}