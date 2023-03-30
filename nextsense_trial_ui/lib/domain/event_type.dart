import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

enum EventTypeKey {
  abbreviation,
  display_name,
  parent_event_type,
  children_event_types,
  full_path
}

class EventType extends FirebaseEntity<EventTypeKey> {
  EventType(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());

  String getAbbreviation() {
    return getValue(EventTypeKey.abbreviation);
  }

  String getDisplayName() {
    return getValue(EventTypeKey.display_name);
  }

  String getFullPath() {
    return getValue(EventTypeKey.full_path);
  }

  String getParentEventType() {
    return getValue(EventTypeKey.parent_event_type);
  }

  List<String> getChildrenEventTypes() {
    return getValue(EventTypeKey.children_event_types);
  }
}