import 'package:health/health.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:logging/logging.dart';

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

  static const String healthConnectSource = "com.google.android.apps.healthdata";
  static const String fitnessSource = "com.google.android.apps.fitness";

  final _health = HealthFactory(useHealthConnectIfAvailable: true);
  final _logger = Logger('GoogleFitManager');

  bool _available = false;
  List<HealthDataType> _availableTypes = [];
  bool _authorized = false;
  List<HealthDataPoint>? _sleepSessions;

  Future<bool> isAvailable() async {
    _available = await InstalledApps.isAppInstalled(healthConnectSource) ?? false;
    if (!_available) {
      _available = await InstalledApps.isAppInstalled(fitnessSource) ?? false;
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

  /// Requests authorization to access health data.
  Future<bool> authorize() async {
    if (_authorized) {
      return true;
    }
    try {
      if (await _health.hasPermissions(_availableTypes) ?? false) {
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
    if (healthData.isEmpty) {
      _logger.log(Level.INFO, "No health data points found");
    } else {
      _logger.log(Level.INFO, "Sleep data point value: ${healthData[0].value}");
    }
    return _sleepSessions;
  }
}