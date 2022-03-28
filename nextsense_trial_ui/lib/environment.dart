import 'package:flutter_dotenv/flutter_dotenv.dart';

final environmentFileName = "env";

enum EnvironmentKey {
  USERNAME,
  PASSWORD,
  USE_EMULATED_BLE,
  AUTO_CONNECT_AFTER_SCAN,
  NEXTSENSE_API_URL
}

Future initEnvironment() async {
  try {
    await dotenv.load(fileName: environmentFileName);
  } catch (e) {
    print('dotenv init failed. Check path "$environmentFileName" exist');
    rethrow;
  }
}

String envGet(EnvironmentKey key, {String? fallback}) {
  return dotenv.get(key.name, fallback: fallback ?? "");
}

bool envGetBool(EnvironmentKey key, bool fallback) {
  return envGet(key, fallback: fallback ? "true" : "false")
      .toLowerCase() == "true";
}



