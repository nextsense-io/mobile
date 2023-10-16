import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:nextsense_base/nextsense_base.dart';
import 'package:flutter_common/domain/firebase_entity.dart';

/// Each entry corresponds to a field name in the database instance.
/// If any fields are added here, they need to be added to the User class in
/// https://github.com/nextsense-io/mobile_backend/lib/models/user.py
enum UserKey {
  // User's email address.
  email,
  // BigTable key. Generated as a UUID.
  bt_key,
  // FCM Token for push notifications
  fcm_token,
  // If the password is temporary (first login or reset by our support).
  is_temp_password,
  // Last login datetime. null if never logged on.
  last_login,
  // ID of the last paired device.
  last_paired_device_id,
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
  // Standard user of the app.
  consumer,
}

class User extends FirebaseEntity<UserKey> {
  
  UserType get userType => getUserTypeFromString(getValue(UserKey.type));

  User(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());

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

  String? getEmail() {
    return getValue(UserKey.email);
  }

  String? getUsername() {
    return getValue(UserKey.username);
  }

  // Future<dynamic> getRunningProtocol(DateTime? studyStartDate, DateTime? studyEndDate) async {
  //   dynamic runningProtocolRef = getValue(UserKey.running_protocol);
  //   if (runningProtocolRef == null) {
  //     return null;
  //   }
  //   DocumentReference ref = runningProtocolRef as DocumentReference;
  //   if (runningProtocolRef.parent.path.toString().endsWith(Table.adhoc_sessions.name())) {
  //     return AdhocSession.fromRecord(
  //         AdhocProtocolRecord(FirebaseEntity(await ref.get(), super.getFirestoreManager())),
  //         getCurrentStudyId()!);
  //   } else {
  //     if (studyStartDate == null || studyEndDate == null) {
  //       throw Exception("Study start and end dates are required for scheduled protocols");
  //     }
  //     FirebaseEntity scheduledProtocolEntity = FirebaseEntity(
  //         await ref.get(), getFirestoreManager());
  //     FirebaseEntity plannedAssessmentEntity = FirebaseEntity(
  //         await (scheduledProtocolEntity.getValue(ScheduledSessionKey.planned_session_id)
  //         as DocumentReference).get(), getFirestoreManager());
  //     PlannedSession plannedAssessment =
  //         PlannedSession(plannedAssessmentEntity, studyStartDate, studyEndDate);
  //     return ScheduledSession(scheduledProtocolEntity, plannedAssessment);
  //   }
  // }

  void setRunningProtocol(DocumentReference? runnableProtocol) {
    setValue(UserKey.running_protocol, runnableProtocol);
  }

  static UserType getUserTypeFromString(String? userTypeStr) {
    return UserType.values.firstWhere((element) => userTypeStr?.contains(element.name) ?? false,
        orElse: () => UserType.unknown);
  }
}
