import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum EventKey {
  // Text marker that identify the event.
  marker,
  // When the event started as a GMT timestamp.
  start_time,
  // When the event finished as a GMT timestamp.
  end_time
}

class Event extends FirebaseEntity<EventKey> {

  Event(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());
}