import 'package:flutter_common/domain/firebase_entity.dart';

import '../di.dart';
import '../domain/event_type.dart';
import 'consumer_ui_firestore_manager.dart';

class EventTypesManager {
  
  final ConsumerUiFirestoreManager _firestoreManager = getIt<ConsumerUiFirestoreManager>();

  final Map<String, EventType> _eventTypes = {};

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