import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/domain/event_type.dart';
import 'package:nextsense_consumer_ui/managers/consumer_ui_firestore_manager.dart';
import 'package:flutter_common/domain/firebase_entity.dart';

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