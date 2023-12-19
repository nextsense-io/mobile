import 'package:health/health.dart';
import 'package:logging/logging.dart';

enum FitResult {
  SUCCESS,
  UNAUTHORIZED,
  NO_DATA
}

class HealthConnectManager {

  static const types = [
    HealthDataType.SLEEP_SESSION
  ];

  static const String fitnessSource = "com.google.android.apps.fitness";

  final _health = HealthFactory(useHealthConnectIfAvailable: true);
  final _logger = Logger('GoogleFitManager');

  bool _authorized = false;
  List<HealthDataPoint>? _sleepSessions;

  /// Requests authorization to access health data.
  Future<bool> authorize() async {
    if (_authorized) {
      return true;
    }
    if (await _health.hasPermissions(types) ?? false) {
      _authorized = true;
      return true;
    }
    _logger.log(Level.INFO, "Requesting health connect authorization");
    bool requested = await _health.requestAuthorization(types);
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
        startDate, endDate, types);
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