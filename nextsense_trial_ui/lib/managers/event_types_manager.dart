import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/event_type.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

class EventTypesManager {
  
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  Map<String, EventType> _eventTypes = {};

  Future<bool> loadEventTypes() async {
    List<FirebaseEntity>? eventTypeEntities = await _firestoreManager.queryEntities(
        [Table.event_types], []);
    if (eventTypeEntities != null) {
      List<EventType> eventTypes = eventTypeEntities.map((entity) => EventType(entity)).toList();
      for (EventType eventType in eventTypes) {
        _eventTypes[eventType.getAbbreviation()] = eventType;
      }
    }
    return true;
  }

  EventType? getEventType(String abbreviation) {
    return _eventTypes[abbreviation];
  }
}