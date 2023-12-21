import 'package:lucid_reality/domain/reality_test.dart';
import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';

enum RealityCheckKey {
  id,
  startTime,
  endTime,
  bedTime,
  wakeTime,
  numberOfReminders,
  realityTest,
}

class RealityCheckEntity extends FirebaseRealtimeDBEntity<RealityCheckKey> {
  static const String table = 'realityChecks';

  RealityCheckEntity._privateConstructor();

  static final RealityCheckEntity _instance = RealityCheckEntity._privateConstructor();

  static RealityCheckEntity get instance => _instance;

  String? getId() {
    return getValue(RealityCheckKey.id);
  }

  int? getStartTime() {
    return getValue(RealityCheckKey.startTime);
  }

  int? getEndTime() {
    return getValue(RealityCheckKey.endTime);
  }

  int? getWakeTime() {
    return getValue(RealityCheckKey.wakeTime);
  }

  int? getBedTime() {
    return getValue(RealityCheckKey.bedTime);
  }

  int getNumberOfReminders() {
    return getValue(RealityCheckKey.numberOfReminders) ?? 0;
  }

  RealityTest? getRealityTest() {
    final obj = getValue(RealityCheckKey.realityTest);
    return obj != null ? RealityTest.fromJson(obj) : null;
  }

  void setId(String id) {
    setValue(RealityCheckKey.id, id);
  }

  void setStartTime(int startTime) {
    setValue(RealityCheckKey.startTime, startTime);
  }

  void setEndTime(int endTime) {
    return setValue(RealityCheckKey.endTime, endTime);
  }

  void setWakeTime(int wakeTime) {
    return setValue(RealityCheckKey.wakeTime, wakeTime);
  }

  void setBedTime(int bedTime) {
    return setValue(RealityCheckKey.bedTime, bedTime);
  }

  void setNumberOfReminders(int numberOfReminders) {
    setValue(RealityCheckKey.numberOfReminders, numberOfReminders);
  }

  void setRealityTest(RealityTest realityTest) {
    setValue(RealityCheckKey.realityTest, realityTest.getValues());
  }

  factory RealityCheckEntity.fromJson(MapEntry<String, dynamic> e) {
    RealityCheckEntity instance = RealityCheckEntity.instance;
    instance.entityId = e.key;
    instance.setValues(Map.from(e.value));
    return instance;
  }
}
