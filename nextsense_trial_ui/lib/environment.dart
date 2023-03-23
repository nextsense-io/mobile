import 'package:flutter_dotenv/flutter_dotenv.dart';

const environmentFileName = "env";
const productionEnvName = "Prod";
const developmentEnvName = "Dev";
const scratchEnvName = "Scratch";

enum EnvironmentKey {
  USERNAME,
  PASSWORD,
  USE_EMULATED_BLE,
  AUTO_CONNECT_AFTER_SCAN
}

Future initEnvironmentFile() async {
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

abstract class Environment {
  String get name;
  String get nextsenseApiUrl;
}

class ScratchEnvironment extends Environment {
  @override
  String get name => "Scratch";

  @override
  String get nextsenseApiUrl => "https://mobile-backend-4hye4mnf2q-uc.a.run.app";
}

class DevelopmentEnvironment extends Environment {
  @override
  String get name => "Development";

  @override
  String get nextsenseApiUrl => "https://mobile-backend-4hye4mnf2q-uc.a.run.app";
}

class ProductionEnvironment extends Environment {
  @override
  String get name => "Production";

  @override
  String get nextsenseApiUrl => "https://mobile-backend-sldjekva7q-uc.a.run.app";
}

class EnvironmentFactory {
  static Environment createEnvironment(String? flavor) {
    if (flavor == null) {
      return ProductionEnvironment();
    }
    if (flavor.contains(productionEnvName)) {
      return ProductionEnvironment();
    } else if (flavor.contains(developmentEnvName)) {
      return DevelopmentEnvironment();
    } else if (flavor.contains(scratchEnvName)) {
      return ScratchEnvironment();
    }
    throw("Unknown environment: $flavor");
  }
}
