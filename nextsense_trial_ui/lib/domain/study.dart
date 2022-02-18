import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum StudyKey {
  // Determines if the study is currently active. If the study is inactive, new
  // data cannot be added to it.
  active,
  // Array of allowed protocols that can be recorded in this study.
  allowed_protocols,
  // Duration in days for a single subject.
  duration_days,
  // Array of lines to show when enrolling a new patient in the study or
  // whenever they want to see it again.
  intro_text,
  // If medication tracking is enabled for this study.
  medication_tracking,
  // Name of the study.
  name,
  // Array of recording site organization ids where this study is running.
  recording_sites,
  // If seizure tracking is enabled for this study.
  seizure_tracking,
  // If side effects tracking is enabled for this study.
  side_effects_tracking,
  // If sleep tracking is enabled for this study.
  sleep_tracking,
  // Link to an image that can be shown in the intro page to this study.
  // Downloaded and cached locally.
  splash_page,
  // organization id of the main sponsor to this study.
  sponsor_id
}

class Study extends FirebaseEntity {

  Study(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  dynamic getValue(StudyKey studyKey) {
    return getValues()[studyKey.name];
  }

  void setValue(StudyKey studyKey, dynamic value) {
    getValues()[studyKey.name] = value;
  }
}