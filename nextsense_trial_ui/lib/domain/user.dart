import 'package:cloud_firestore/cloud_firestore.dart';
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
}