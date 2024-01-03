import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';

enum RealityTestKey {
  realityTestID,
  name,
  description,
  image,
  totemSound,
  type,
}

class RealityTest extends FirebaseRealtimeDBEntity<RealityTestKey> {
  RealityTest._privateConstructor();

  static final RealityTest _instance = RealityTest._privateConstructor();

  static RealityTest get instance => _instance;

  String? getRealityTestID() {
    return getValue(RealityTestKey.realityTestID);
  }

  String? getName() {
    return getValue(RealityTestKey.name);
  }

  String? getDescription() {
    return getValue(RealityTestKey.description);
  }

  String? getImage() {
    return getValue(RealityTestKey.image);
  }

  String? getTotemSound() {
    return getValue(RealityTestKey.totemSound);
  }

  void setRealityTestID(String realityTestID) {
    setValue(RealityTestKey.realityTestID, realityTestID);
  }

  void setName(String name) {
    setValue(RealityTestKey.name, name);
  }

  void setDescription(String description) {
    setValue(RealityTestKey.description, description);
  }

  void setImage(String image) {
    setValue(RealityTestKey.image, image);
  }

  void setTotemSound(String totemSound) {
    setValue(RealityTestKey.totemSound, totemSound);
  }

  void setType(String type) {
    setValue(RealityTestKey.type, type);
  }

  factory RealityTest.fromJson(Map<dynamic, dynamic> data) {
    RealityTest realityTest = RealityTest.instance;
    try {
      if (data.entries.isNotEmpty) {
        realityTest.setValues(Map<String, dynamic>.fromEntries(
            data.entries.map((e) => MapEntry(e.key.toString(), e.value))));
      }
    } catch (e) {
      print(e);
    }
    return realityTest;
  }
}
