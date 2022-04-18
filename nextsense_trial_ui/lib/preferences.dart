
import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceKey {
  authToken,
  allowDataTransmissionViaCellular,
  showDayTabsForTasks
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

  // Determines that entity specified by 'key' is cached
  bool isCached(String key) {
    return sharedPrefs.getBool(key) ?? false;
  }

  // Mark entity specified by 'key' as cached
  void markAsCached(String key) {
    sharedPrefs.setBool(key, true);
  }

}