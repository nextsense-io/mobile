import 'package:flutter_common/di.dart';
import 'package:health/health.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/domain/user_entity.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';
import 'package:url_launcher/url_launcher.dart';

enum FitResult {
  SUCCESS,
  UNAUTHORIZED,
  NO_DATA
}

class HealthConnectManager {
  static const types = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT
  ];

  static const String healthConnectPackage = "com.google.android.apps.healthdata";
  static const String fitnessPackage = "com.google.android.apps.fitness";
  static const String fitbitPackage = "com.fitbit.FitbitMobile";
  static const String samsungHealthPackage = "com.sec.android.app.shealth";

  final _firebaseRealTimeDb = getIt<LucidUiFirebaseRealtimeDBManager>();
  final _authManager = getIt<AuthManager>();
  final _health = HealthFactory(useHealthConnectIfAvailable: true);
  final _logger = Logger('GoogleFitManager');

  bool _available = false;
  List<HealthDataType> _availableTypes = [];
  bool _authorized = false;
  List<HealthDataPoint>? _sleepSessions;

  Future<bool> isAvailable() async {
    _available = await InstalledApps.isAppInstalled(healthConnectPackage) ?? false;
    if (!_available) {
      _available = await InstalledApps.isAppInstalled(fitnessPackage) ?? false;
    }
    _availableTypes = [];
    for (HealthDataType type in types) {
      if (_health.isDataTypeAvailable(type)) {
        _availableTypes.add(type);
      }
    }
    if (_availableTypes.isEmpty) {
      _logger.log(Level.INFO, "No health data types available.");
      return false;
    }
    return _available;
  }

  installHealthConnect() async {
    final healthConnectUrl = Uri.parse("market://details?id=$healthConnectPackage");
    launchUrl(healthConnectUrl, mode: LaunchMode.externalApplication);
  }

  openFitbitApp() {
    InstalledApps.startApp(fitbitPackage);
  }

  openSamsungHealthApp() {
    InstalledApps.startApp(samsungHealthPackage);
  }

  openGoogleFitApp() {
    InstalledApps.startApp(fitnessPackage);
  }

  Future<bool?> isAuthorized() async {
    _authorized = await _health.hasPermissions(_availableTypes) ?? false;
    return _authorized;
  }

  /// Requests authorization to access health data.
  Future<bool> authorize() async {
    if (_authorized) {
      return true;
    }
    try {
      if (await isAuthorized() ?? false) {
        _authorized = true;
        return true;
      }
    } on Exception catch (e) {
      _logger.log(Level.INFO, "Health type not available: $e");
      return false;
    }
    _logger.log(Level.INFO, "Requesting health connect authorization");
    bool requested = await _health.requestAuthorization(_availableTypes);
    if (!requested) {
      _logger.log(Level.INFO, "Health connect authorization request failed");
      return false;
    }
    _authorized = true;
    return true;
  }

  /// Returns a list of sleep session data points for the last [days] days.
  /// Returns null if the user is not authorized.
  /// Returns an empty list if no data is available.
  Future<List<HealthDataPoint>?> getSleepSessionData(
      {required DateTime startDate, required int days}) async {
    if (days < 1) {
      throw ArgumentError("Days must be greater than 0");
    }

    if (!_authorized) {
      _logger.log(Level.INFO, "Health connect authorization missing.");
      return null;
    }
    DateTime endDate = startDate.add(Duration(days: days));
    _logger.log(Level.INFO, "Requesting health data from $startDate to $endDate");
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startDate, endDate, _availableTypes);
    _logger.log(Level.INFO, "Received ${healthData.length} health data points");
    _sleepSessions = healthData;
    if (healthData.isNotEmpty) {
      if ((_authManager.user?.getReadSleepData() ?? false) == false) {
        _authManager.user?.setReadSleepData(true);
        await _firebaseRealTimeDb.updateEntity(_authManager.user!, UserEntity.table);
      }
    } else {
      _logger.log(Level.INFO, "No health data points found");
    }
    return _sleepSessions;
  }
}