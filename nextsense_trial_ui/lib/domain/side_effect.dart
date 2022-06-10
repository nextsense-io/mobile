import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/timed_entry.dart';

// List of side effect types that can be entered by the user.
enum SideEffectType {
  dizziness('Dizziness'),
  sleep_issues('Sleep issues'),
  anxiety('Anxiety'),
  tiredness('Tiredness'),
  depression('Depression'),
  headache('Headache'),
  memory_loss('Memory loss'),
  missed_poor_sleep('Missed/poor sleep'),
  mood_change('Mood change'),
  upset_stomach('Upset stomach'),
  skin_issues('Skin issues'),
  mouth_issues('Mouth issues'),
  other('Other');

  const SideEffectType(this.label);
  final String label;
}

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum SideEffectKey {
  // Start date and time of the side effect.
  start_datetime,
  // End date and time of the side effect.
  end_datetime,
  // List of side effects that were experienced at that time.
  side_effect_types,
  // Open-ended notes on the side effects by the user.
  user_notes
}

class SideEffect extends FirebaseEntity<SideEffectKey> implements TimedEntry {

  SideEffect(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());

  DateTime? getStartDateTime() {
    final value = getValue(SideEffectKey.start_datetime);
    return value != null ? (value as Timestamp).toDate() : null;
  }

  DateTime? getEndDateTime() {
    final value = getValue(SideEffectKey.end_datetime);
    return value != null ? (value as Timestamp).toDate() : null;
  }

  List<String> getSideEffectTypes() {
    final value = getValue(SideEffectKey.side_effect_types);
    return value != null ? List<String>.from(value) : [];
  }

  String getUserNotes() {
    final value = getValue(SideEffectKey.user_notes);
    return value != null ? (value as String) : '';
  }

  @override
  DateTime get dateTime => getStartDateTime()!;
}