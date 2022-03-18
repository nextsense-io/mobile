
import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceKey {
  allowDataTransmissionViaCellular
}

class Preferences {
  late SharedPreferences sharedPrefs;

  Future init() async {
    sharedPrefs = await SharedPreferences.getInstance();
  }

  void setBool(PreferenceKey key, bool val)
  {
    sharedPrefs.setBool(key.name, val);
  }

  bool getBool(PreferenceKey key)
  {
    return sharedPrefs.getBool(key.name) ?? false;
  }

}