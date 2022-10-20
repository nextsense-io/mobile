import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/adhoc_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

/// Each entry corresponds to a field name in the database instance.
/// If any fields are added here, they need to be added to the User class in
/// https://github.com/nextsense-io/mobile_backend/lib/models/user.py
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
  username,
  // Currently recording protocol
  running_protocol,
  // UID used when authenticating
  auth_uid
}

enum UserType {
  // Unknown user type as a fallback.
  unknown,
  // Anonymous participant in a clinical study. One code per participant per study to maintain
  // anonymity. So will only have one enrolled study.
  anonymous_subject,
  // Participant in a clinical study with an email as login id.
  subject,
  // Researcher using the device run tests. Can have multiple active enrolled studies at the same
  // time. More control options with the device.
  researcher
}

class User extends FirebaseEntity<UserKey> {
  
  UserType get userType => getUserTypeFromString(getValue(UserKey.type));

  User(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  String? getCurrentStudy() {
    return getValue(UserKey.current_study);
  }

  String? getLastPairedDeviceMacAddress() {
    final value = getValue(UserKey.last_paired_device);
    return value != null ? (value as String) : null;
  }

  void setLastPairedDeviceMacAddress(String? macAddress) {
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
    return isTempPassword != null ? isTempPassword : true;
  }

  void setTempPassword(bool tempPassword) {
    setValue(UserKey.is_temp_password, tempPassword);
  }

  Future<dynamic?> getRunningProtocol() async {
    dynamic? runningProtocolRef = getValue(UserKey.running_protocol);
    if (runningProtocolRef == null) {
      return null;
    }
    if (runningProtocolRef.parent.path.toString().endsWith(Table.adhoc_protocols.name())) {
      DocumentReference ref = runningProtocolRef as DocumentReference;
      return AdhocProtocol.fromRecord(
          AdhocProtocolRecord(FirebaseEntity(await ref.get())), getCurrentStudy()!);
    } else {
      return ScheduledProtocol(runningProtocolRef, runningProtocolRef['protocol']);
    }
  }

  void setRunningProtocol(DocumentReference? runnableProtocol) {
    setValue(UserKey.running_protocol, runnableProtocol);
  }

  static UserType getUserTypeFromString(String? userTypeStr) {
    return UserType.values.firstWhere((element) => userTypeStr?.contains(element.name) ?? false,
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
