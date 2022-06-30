import 'dart:core';

import 'package:nextsense_trial_ui/environment.dart';

class Config {
  // Used for going directly to dashboard after scan
  static bool get autoConnectAfterScan => envGetBool(EnvironmentKey.AUTO_CONNECT_AFTER_SCAN, false);

  static bool get useEmulatedBle => envGetBool(EnvironmentKey.USE_EMULATED_BLE, false);

  static String get nextsenseApiUrl => envGet(EnvironmentKey.NEXTSENSE_API_URL);
}