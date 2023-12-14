import 'package:health/health.dart';
import 'package:logging/logging.dart';

enum FitResult {
  SUCCESS,
  UNAUTHORIZED,
  NO_DATA
}

class GoogleFitManager {

  static const types = [
    HealthDataType.SLEEP_SESSION
  ];

  final _health = HealthFactory(useHealthConnectIfAvailable: true);
  final _logger = Logger('GoogleFitManager');

  bool _authorized = false;
  List<HealthDataPoint>? _sleepSessions;

  Future<bool> authorize() async {
    if (_authorized) {
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

  Future<List<HealthDataPoint>?> getSleepSessionData(int days) async {
    if (_sleepSessions != null) {
      return _sleepSessions;
    }
    if (!_authorized) {
      _logger.log(Level.INFO, "Health connect authorization missing.");
      return null;
    }
    DateTime now = DateTime.now();
    _logger.log(Level.INFO, "Requesting health data from ${now.subtract(Duration(days: days))} to $now");
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        now.subtract(Duration(days: days)), now, types);
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