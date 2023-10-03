import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceKey {
  allowDataTransmissionViaCellular,
  authToken,
  continuousImpedance,
  studyDataCached,
  fcmToken,
  eegSignalFilterType,
  powerLineFrequency,
  lowCutFrequency,
  highCutFrequency,
  flavor,
  displayDataType,
  displayEegSignalProcessing,
  displaySelectedChannel,
  displayMaxAmplitude,
  displayLowCutFreq,
  displayHighCutFreq,
  displayPowerLineFreq,
  displayEegTimeWindowSeconds,
  displayAccTimeWindowSeconds,
}

class Preferences {
  late SharedPreferences sharedPrefs;

  Future init() async {
    sharedPrefs = await SharedPreferences.getInstance();
  }

  void setString(PreferenceKey key, String val) {
    sharedPrefs.setString(key.name, val);
  }

  String? getString(PreferenceKey key) {
    return sharedPrefs.getString(key.name);
  }

  void setBool(PreferenceKey key, bool val) {
    sharedPrefs.setBool(key.name, val);
  }

  bool getBool(PreferenceKey key) {
    return sharedPrefs.getBool(key.name) ?? false;
  }

  void setInt(PreferenceKey key, int val) {
    sharedPrefs.setInt(key.name, val);
  }

  int? getInt(PreferenceKey key) {
    return sharedPrefs.getInt(key.name);
  }

  void setDouble(PreferenceKey key, double val) {
    sharedPrefs.setDouble(key.name, val);
  }

  double? getDouble(PreferenceKey key) {
    return sharedPrefs.getDouble(key.name);
  }

  // Determines that entity specified by 'key' is cached
  bool isCached(String key) {
    return sharedPrefs.getBool(key) ?? false;
  }

  // Mark entity specified by 'key' as cached
  void markAsCached(String key) {
    sharedPrefs.setBool(key, true);
  }
}
