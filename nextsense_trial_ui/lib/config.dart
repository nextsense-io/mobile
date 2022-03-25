import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // This should be changed also in Config.java
  static final bool useEmulatedBle = false;

  // Used for going directly to dashboard
  static final bool autoConnectAfterScan = false;

  static String get nextsenseApiUrl {
    return dotenv.env["NEXTSENSE_API_URL"]!;
  }

}