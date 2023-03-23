import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/adhoc_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:timezone/timezone.dart' as tz;

/// Each entry corresponds to a field name in the database instance.
/// If any fields are added here, they need to be added to the User class in
/// https://github.com/nextsense-io/mobile_backend/lib/models/user.py
enum UserKey {
  // UID used when authenticating.
  auth_uid,
  // User's email address.
  email,
  // BigTable key. Generated as a UUID.
  bt_key,
  // Currently selected study. Opens by default if there are more than one for
  // this user, which is possible for some user types.
  current_study_id,
  // FCM Token for push notifications
  fcm_token,
  // If the password is temporary (first login or reset by our support).
  is_temp_password,
  // Last login datetime. null if never logged on.
  last_login,
  // ID of the last paired device.
  last_paired_device_id,
  // Organization ID
  organization_id,
  // String containing the salted and hashed password.
  password,
  // Currently recording protocol
  running_protocol,
  // How many sessions were recorded by this user.
  session_number,
  // Current user's timezone
  timezone,
  // User type.
  type,
  // User name
  username,
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

  String? getCurrentStudyId() {
    return getValue(UserKey.current_study_id);
  }

  String? getLastPairedDeviceMacAddress() {
    final value = getValue(UserKey.last_paired_device_id);
    return value != null ? (value as String) : null;
  }

  void setLastPairedDeviceMacAddress(String? macAddress) {
    setValue(UserKey.last_paired_device_id, macAddress);
  }

  void setFcmToken(String fcmToken) {
    setValue(UserKey.fcm_token, fcmToken);
  }

  DateTime? getLastLogin() {
    final Timestamp? lastLoginDateTime = getValue(UserKey.last_login);
    return lastLoginDateTime != null ? lastLoginDateTime.toDate() : null;
  }

  void setLastLogin(DateTime dateTime) {
    setValue(UserKey.last_login, dateTime);
  }

  Future updateTimezone() async {
    setValue(UserKey.timezone, await NextsenseBase.getTimezoneId());
  }

  tz.Location getCurrentTimezone() {
    return tz.getLocation(getValue(UserKey.timezone));
  }

  bool isTempPassword() {
    bool? isTempPassword = getValue(UserKey.is_temp_password);
    return isTempPassword != null ? isTempPassword : false;
  }

  void setTempPassword(bool tempPassword) {
    setValue(UserKey.is_temp_password, tempPassword);
  }

  Future<dynamic> getRunningProtocol(DateTime? studyStartDate, DateTime? studyEndDate) async {
    dynamic runningProtocolRef = getValue(UserKey.running_protocol);
    if (runningProtocolRef == null) {
      return null;
    }
    DocumentReference ref = runningProtocolRef as DocumentReference;
    if (runningProtocolRef.parent.path.toString().endsWith(Table.adhoc_protocols.name())) {
      return AdhocProtocol.fromRecord(
          AdhocProtocolRecord(FirebaseEntity(await ref.get())), getCurrentStudyId()!);
    } else {
      if (studyStartDate == null || studyEndDate == null) {
        throw Exception("Study start and end dates are required for scheduled protocols");
      }
      FirebaseEntity scheduledProtocolEntity = FirebaseEntity(await ref.get());
      FirebaseEntity plannedAssessmentEntity = FirebaseEntity(
          await (scheduledProtocolEntity.getValue(ScheduledProtocolKey.protocol)
          as DocumentReference).get());
      PlannedAssessment plannedAssessment =
          PlannedAssessment(plannedAssessmentEntity, studyStartDate, studyEndDate);
      return ScheduledProtocol(scheduledProtocolEntity, plannedAssessment);
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
