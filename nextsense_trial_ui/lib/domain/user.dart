import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum UserKey {
  // MAC address of the last paired device.
  last_paired_device,
  // String containing the salt and hashed password.
  password,
  // Currently selected study. Opens by default if there are more than one for
  // this user, which is possible for some user types.
  current_study,
  // User type.
  type,
  // BigTable key. Generated as a UUID.
  bt_key,
  // How many sessions were recorded by this user.
  session_number
}

class User extends FirebaseEntity<UserKey> {

  User(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  String? getLastPairedDeviceMacAddress() {
    final value = getValue(UserKey.last_paired_device);
    return value != null ? (value as String) : null;
  }

  void setLastPairedDeviceMacAddress(String macAddress) {
    setValue(UserKey.last_paired_device, macAddress);
  }

  /**
   * Checks that the current date is between the study start and end dates for
   * this subject if present.
   *
   * If not in between, return the number of days it is before as a negative and
   * after as a positive.
   */
  // TODO(alex): this code need to be fixed
  /*int verifyStudyDates() {
    DateTime now = DateTime.now();
    String? startDateTimeString = getValue(UserKey.study_start_date);
    if (startDateTimeString != null) {
      DateTime startDateTime = DateTime.parse(startDateTimeString);
      if (now.isBefore(startDateTime)) {
        return now.difference(startDateTime).inDays;
      }
    }
    String? endDateTimeString = getValue(UserKey.study_end_date);
    if (endDateTimeString != null) {
      DateTime endDateTime = DateTime.parse(endDateTimeString);
      if (now.isAfter(endDateTime)) {
        return now.difference(endDateTime).inDays;
      }
    }
    return 0;
  }*/
}