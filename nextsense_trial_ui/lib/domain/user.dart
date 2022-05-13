import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 * If any fields are added here, they need to be added to the User class in
 * https://github.com/nextsense-io/mobile_backend/lib/models/user.py
 */
enum UserKey {
  // MAC address of the last paired device.
  last_paired_device,
  // String containing the salt and hashed password.
  password,
  // If the password is temporary (first login or reset by our support).
  is_temp_password,
  // Currently selected study. Opens by default if there are more than one for
  // this user, which is possible for some user types.
  current_study,
  // User type.
  type,
  // BigTable key. Generated as a UUID.
  bt_key,
  // How many sessions were recorded by this user.
  session_number,
  // FCM Token for push notifications
  fcm_token,
  // Current user's timezone
  timezone,
  // User name
  username
}

enum UserType {
  // Unknown user type as a fallback.
  unknown,
  // Participant in a clinical study. One code per participant per study to
  // maintain anonymity. So will only have one enrolled study.
  subject,
  // Researcher using the device run tests. Can have multiple active enrolled
  // studies at the same time.
  researcher
}

class User extends FirebaseEntity<UserKey> {
  
  UserType get userType => getUserTypeFromString(getValue(UserKey.type));

  User(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  String? getLastPairedDeviceMacAddress() {
    final value = getValue(UserKey.last_paired_device);
    return value != null ? (value as String) : null;
  }

  void setLastPairedDeviceMacAddress(String macAddress) {
    setValue(UserKey.last_paired_device, macAddress);
  }

  void setFcmToken(String fcmToken) {
    setValue(UserKey.fcm_token, fcmToken);
  }

  Future updateTimezone() async {
    setValue(UserKey.timezone, await NextsenseBase.getTimezoneId());
  }

  bool isTempPassword() {
    bool? isTempPassword = getValue(UserKey.is_temp_password);
    return isTempPassword != null ? isTempPassword : false;
  }

  static UserType getUserTypeFromString(String? userTypeStr) {
    return UserType.values.firstWhere((element) => element.name == userTypeStr,
        orElse: () => UserType.unknown);
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
