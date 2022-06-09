import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum EventKey {
  // Identify the event
  marker,
  // When the event started
  start_time,
  // When the event finished
  end_time
}

class Event extends FirebaseEntity<EventKey> {

  Event(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());
}