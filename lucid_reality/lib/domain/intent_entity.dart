import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';

enum IntentKey { id, description, categoryID, realityCheckID, createdAt, updatedAt }

class IntentEntity extends FirebaseRealtimeDBEntity<IntentKey> {
  static const String table = 'intents';

  IntentEntity._privateConstructor();

  static final IntentEntity _instance = IntentEntity._privateConstructor();

  static IntentEntity get instance => _instance;

  String? getId() {
    return getValue(IntentKey.id);
  }

  String? getDescription() {
    return getValue(IntentKey.description);
  }

  String? getCategoryID() {
    return getValue(IntentKey.categoryID);
  }

  String? getRealityCheckID() {
    return getValue(IntentKey.realityCheckID);
  }

  int? getCreatedAt() {
    return getValue(IntentKey.createdAt);
  }

  int? getUpdatedAt() {
    return getValue(IntentKey.updatedAt);
  }

  void setDescription(String description) {
    setValue(IntentKey.description, description);
  }

  void setCategoryID(String categoryID) {
    setValue(IntentKey.categoryID, categoryID);
  }

  void setRealityCheckID(String realityCheckID) {
    setValue(IntentKey.realityCheckID, realityCheckID);
  }

  void setCreatedAt(DateTime createdAt) {
    setValue(IntentKey.createdAt, createdAt.millisecondsSinceEpoch);
  }

  void setUpdatedAt(DateTime updatedAt) {
    setValue(IntentKey.updatedAt, updatedAt.millisecondsSinceEpoch);
  }

  void setId(String? id) {
    setValue(IntentKey.id, id);
  }

  factory IntentEntity.fromJson(MapEntry<String, dynamic> e) {
    IntentEntity instance = IntentEntity.instance;
    instance.entityId = e.key;
    instance.setValues(Map.from(e.value));
    return instance;
  }
}
