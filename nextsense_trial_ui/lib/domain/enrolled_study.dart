import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum EnrolledStudyKey {
  // Study is initialized on device and we can use cached entities
  initialized,
  // Starting date of the currently enrolled study for this subject.
  start_date,
  // Ending date of the currently enrolled study for this subject.
  end_date,
}

class EnrolledStudy extends FirebaseEntity<EnrolledStudyKey> {

  EnrolledStudy(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  bool get initialized =>
      getValue(EnrolledStudyKey.initialized) ?? false;

  void setInitialized(bool initialized) {
    setValue(EnrolledStudyKey.initialized, true);
  }

  DateTime? getStartDate() {
    final value = getValue(EnrolledStudyKey.start_date);
    return value != null ? (value as Timestamp).toDate() : null;
  }

  DateTime? getEndDate() {
    final value = getValue(EnrolledStudyKey.end_date);
    return value != null ? (value as Timestamp).toDate() : null;
  }
}