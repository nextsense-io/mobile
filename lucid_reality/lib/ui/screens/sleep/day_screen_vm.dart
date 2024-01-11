import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:health/health.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/managers/health_connect_manager.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';

class DayScreenViewModel extends ViewModel {
  static const List<LucidSleepStage> pieChartStages = [
    LucidSleepStage.core,
    LucidSleepStage.deep,
    LucidSleepStage.rem,
    LucidSleepStage.awake
  ];

  final _healthConnectManager = getIt<HealthConnectManager>();
  final _logger = getLogger("DayScreenViewModel");

  bool? _healthAppInstalled;
  bool? _healthAppAuthorized;
  List<HealthDataPoint>? _healthDataPoints;
  DateTime _currentDate = DateTime.now().dateNoTime;
  SleepResultType _sleepResultType = SleepResultType.noData;
  Duration _totalSleepTime = Duration.zero;
  DateTime? _sleepStartTime;
  DateTime? _sleepEndTime;
  List<ChartSleepStage> _chartSleepStages = [];

  bool get healthAppInstalled => _healthAppInstalled ?? false;
  bool get healthAppAuthorized => _healthAppAuthorized ?? false;
  DateTime get currentDate => _currentDate;
  SleepResultType get sleepResultType => _sleepResultType;
  String get totalSleepTime => _totalSleepTime == Duration.zero ? "N/A" :
      "${_totalSleepTime.inHours}h ${_totalSleepTime.inMinutes.remainder(60)}m";
  String get sleepStartEndTime => _sleepStartTime == null ? "No sleep data" :
      "${_sleepStartTime!.hmma} - ${_sleepEndTime!.hmma}";
  List<ChartSleepStage> get chartSleepStages => _chartSleepStages;

  void init() async {
    _healthAppInstalled = await _healthConnectManager.isAvailable();
    if (_healthAppInstalled!) {
      _healthAppAuthorized = await _healthConnectManager.authorize();
      if (_healthAppAuthorized!) {
        await _getSleepInfo();
      }
    }
    setInitialised(true);
    notifyListeners();
  }

  Future checkHealthAppInstalled() async {
    _healthAppInstalled = await _healthConnectManager.isAvailable();
    notifyListeners();
  }

  Future authorizeHealthApp() async {
    _healthAppAuthorized = await _healthConnectManager.authorize();
    notifyListeners();
  }

  String formatSleepDuration(Duration duration) {
    return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
  }

  Future _getSleepInfo() async {
    _healthDataPoints = await _healthConnectManager.getSleepSessionData(
        startDate: currentDate, days: 1);
    _chartSleepStages.clear();
    if (_healthDataPoints?.isEmpty ?? true) {
      _sleepResultType = SleepResultType.noData;
      _totalSleepTime = Duration.zero;
      _sleepStartTime = null;
      _sleepEndTime = null;
    } else if (_healthDataPoints!.length == 1 && _healthDataPoints![0].type ==
        HealthDataType.SLEEP_SESSION && _healthDataPoints![0].unit == HealthDataUnit.MINUTE) {
      _sleepResultType = SleepResultType.sleepTimeOnly;
      _totalSleepTime = Duration(minutes: int.parse(_healthDataPoints![0].value.toString()));
      _sleepStartTime = _healthDataPoints![0].dateFrom;
      _sleepEndTime = _healthDataPoints![0].dateTo;
      _chartSleepStages = [
        ChartSleepStage(LucidSleepStage.sleeping.getLabel(), 100, _totalSleepTime,
            LucidSleepStage.sleeping.getColor())];
    } else {
      _sleepResultType = SleepResultType.sleepStaging;

      // Get total duration for each sleep stage in that day.
      Map<LucidSleepStage, Duration> sleepStageDurations = {};
      for (LucidSleepStage lucidSleepStage in LucidSleepStage.values) {
        sleepStageDurations[lucidSleepStage] = Duration.zero;
      }
      _sleepStartTime = null;
      _sleepEndTime = null;
      for (HealthDataPoint dataPoint in _healthDataPoints!) {
        if (dataPoint.unit == HealthDataUnit.MINUTE) {
          LucidSleepStage lucidSleepStage = getSleepStageFromHealthDataPoint(dataPoint);
          Duration sleepStageDuration;
          if (dataPoint.value is int) {
            sleepStageDuration = Duration(minutes: int.parse(dataPoint.value.toString()));
          } else {
            sleepStageDuration = Duration(minutes: double.parse(dataPoint.value.toString()).round());
          }
          sleepStageDurations[lucidSleepStage] = sleepStageDurations[lucidSleepStage]! +
              sleepStageDuration;
          if (pieChartStages.contains(lucidSleepStage)) {
            if (_sleepStartTime == null || _sleepStartTime!.isAfter(dataPoint.dateFrom)) {
              _sleepStartTime = dataPoint.dateFrom;
            }
            if (_sleepEndTime == null || _sleepEndTime!.isBefore(dataPoint.dateTo)) {
              _sleepEndTime = dataPoint.dateTo;
            }
          }
        } else {
          _logger.log(Level.INFO, "Health data point ${dataPoint.type} unit is not minutes");
        }
      }

      // Get total time for all sleep stages.
      _totalSleepTime = Duration.zero;
      for (LucidSleepStage lucidSleepStage in pieChartStages) {
        _totalSleepTime += sleepStageDurations[lucidSleepStage]!;
      }

      // Get sleep stages for pie chart and details.
      for (LucidSleepStage lucidSleepStage in pieChartStages) {
        _chartSleepStages.add(ChartSleepStage(lucidSleepStage.getLabel(),
            (sleepStageDurations[lucidSleepStage]!.inMinutes /
            _totalSleepTime.inMinutes * 100).round(),
            sleepStageDurations[lucidSleepStage]!, lucidSleepStage.getColor()));
      }
    }
  }

  void changeDay(int relativeDayChange) async {
    if (relativeDayChange > 0) {
      _currentDate = _currentDate.add(Duration(days: relativeDayChange));
    } else if (relativeDayChange < 0) {
      _currentDate = _currentDate.subtract(Duration(days: -relativeDayChange));
    } else {
      return;
    }
    await _getSleepInfo();
    notifyListeners();
  }
}