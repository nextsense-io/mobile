import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/timed_entry.dart';

// List of triggers that can be entered by the user.
enum Trigger {
  mood_change('Mood change'),
  temperature_change('Temperature change'),
  missed_late_medication('Missed/late medication'),
  illness('Illness'),
  missed_meal('Missed meal'),
  missed_poor_sleep('Missed/poor sleep'),
  during_sleep_upon_waking('During sleep/upon waking'),
  drugs('Drugs'),
  fast_breathing('Fast breathing'),
  low_blood_sugar('Low blood sugar'),
  stress('Stress'),
  alcohol('Alcohol'),
  other('Other');

  const Trigger(this.label);
  final String label;
}

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum SeizureKey {
  // Start date and time of the seizure.
  start_datetime,
  // End date and time of the seizure.
  end_datetime,
  // List of triggers that were thought to have caused the seizure.
  triggers,
  // Open-ended notes on the seizure by the user.
  user_notes
}

class Seizure extends FirebaseEntity<SeizureKey> implements TimedEntry {

  Seizure(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());

  DateTime? getStartDateTime() {
    final value = getValue(SeizureKey.start_datetime);
    return value != null ? (value as Timestamp).toDate() : null;
  }

  DateTime? getEndDateTime() {
    final value = getValue(SeizureKey.end_datetime);
    return value != null ? (value as Timestamp).toDate() : null;
  }

  List<String> getTriggers() {
    final value = getValue(SeizureKey.triggers);
    return value != null ? List<String>.from(value) : [];
  }

  String getUserNotes() {
    final value = getValue(SeizureKey.user_notes);
    return value != null ? (value as String) : '';
  }

  @override
  DateTime get dateTime => getStartDateTime()!;
}