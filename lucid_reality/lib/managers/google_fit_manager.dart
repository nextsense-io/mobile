import 'package:health/health.dart';

class GoogleFitManager {

  final health = HealthFactory(useHealthConnectIfAvailable: true);

  static const types = [
    HealthDataType.SLEEP_SESSION
  ];

  Future getSleepSessionData() async {
    bool requested = await health.requestAuthorization(types);
    if (!requested) {
      return null;
    }
    DateTime now = DateTime.now();
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        now.subtract(Duration(days: 1)), now, types);
    return healthData[0];
  }

}