import 'dart:core';

import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/environment.dart';

class Config {
  static bool get useEmulatedBle => envGetBool(EnvironmentKey.USE_EMULATED_BLE, false);

  static String get nextsenseApiUrl => getIt.get<Environment>().nextsenseApiUrl;
}