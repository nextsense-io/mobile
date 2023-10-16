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
  // Name of the protocol that was ran to record this session
  protocol_name,
  // Map of protocol specific information that was recorded from the user that is not parts of
  // of the standard events.
  protocol_data,
  // Start of the recording session.
  start_datetime,
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