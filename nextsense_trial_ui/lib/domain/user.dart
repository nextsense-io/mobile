import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum UserKey {
  // MAC address of the last paired device.
  last_paired_device,
  // String containing the salt and hashed password.
  password,
  // Currently enrolled study.
  study,
  // Starting date of the currently enrolled study for this subject.
  study_start_date,
  // Ending date of the currently enrolled study for this subject.
  study_end_date,
  // User type.
  type,
  // BigTable key. Generated as a UUID.
  bt_key,
  // How many sessions were recorded by this user.
  session_number
}

class User extends FirebaseEntity {

  User(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  dynamic getValue(UserKey userKey) {
    return getValues()[userKey.name];
  }

  void setValue(UserKey userKey, dynamic value) {
    getValues()[userKey.name] = value;
  }

  /**
   * Checks that the current date is between the study start and end dates for
   * this subject if present.
   *
   * If not in between, return the number of days it is before as a negative and
   * after as a positive.
   */
  int verifyStudyDates() {
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
  }
}