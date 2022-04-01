
import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceKey {
  authToken,
  allowDataTransmissionViaCellular
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

}