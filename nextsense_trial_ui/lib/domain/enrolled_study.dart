import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/// Each entry corresponds to a field name in the database instance.
enum EnrolledStudyKey {

  // Study has been scheduled for this user.
  is_scheduled,
  // Starting date of the currently enrolled study for this subject.
  start_date,
  // Ending date of the currently enrolled study for this subject.
  end_date,
  // If the study intro should be shown.
  show_intro
}

class EnrolledStudy extends FirebaseEntity<EnrolledStudyKey> {

  EnrolledStudy(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());

  bool get isScheduled => getValue(EnrolledStudyKey.is_scheduled) ?? false;

  void setIsScheduled(bool isScheduled) {
    setValue(EnrolledStudyKey.is_scheduled, isScheduled);
  }

  bool get showIntro => getValue(EnrolledStudyKey.show_intro) ?? true;

  void setShowIntro(bool shown) {
    setValue(EnrolledStudyKey.show_intro, shown);
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