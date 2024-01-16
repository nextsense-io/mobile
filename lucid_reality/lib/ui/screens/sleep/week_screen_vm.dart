import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:health/health.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/managers/health_connect_manager.dart';
import 'package:lucid_reality/ui/components/sleep_bar_chart.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';

class WeekScreenViewModel extends ViewModel {

  final _healthConnectManager = getIt<HealthConnectManager>();
  List<HealthDataPoint>? _healthDataPoints;
  DateTime _weekStartDate = DateTime.now().dateNoTime;
  DateTime _weekEndDate = DateTime.now().dateNoTime;
  SleepResultType _sleepResultType = SleepResultType.noData;
  Map<DateTime, DaySleepStats> _dailySleepStats = {};
  Map<DateTime, List<ChartSleepStage>> _chartSleepStages = {};
  Map<LucidSleepStage, Duration> _sleepStageAverages = {};
  Map<LucidSleepStage, List<DaySleepStage>> _daySleepStages = {};
  Duration? _averageSleepLatency;

  String get weekDateRange  {
    if (_weekStartDate.month == _weekEndDate.month) {
      return "${_weekStartDate.monthDay}-${_weekEndDate.day}, ${_weekEndDate.year}";
    }
    return "${_weekStartDate.monthDay}-${_weekEndDate.monthDay}, ${_weekEndDate.year}";
  }
  DateTime get weekStartDate => _weekStartDate;
  DateTime get weekEndDate => _weekEndDate;
  SleepResultType get sleepResultType => _sleepResultType;
  Map<LucidSleepStage, Duration> get sleepStageAverages => _sleepStageAverages;
  Map<DateTime, List<ChartSleepStage>> get chartSleepStages => _chartSleepStages;
  List<DaySleepStage> get daySleepStages {
    List<DaySleepStage> daySleepStages = _daySleepStages.values.expand((x) => x).toList();
    daySleepStages.sort((a, b) => a.dayOfWeekIndex.compareTo(b.dayOfWeekIndex));
    return daySleepStages;
  }
  Duration? get averageSleepTime => _sleepStageAverages[LucidSleepStage.sleeping];
  Duration? get averageSleepLatency => _averageSleepLatency;

  void init() async {
    _weekStartDate = findFirstDateOfTheWeek(DateTime.now().dateNoTime);
    _weekEndDate = _weekStartDate.add(Duration(days: 6));
    await _healthConnectManager.authorize();
    await _getSleepInfo();
    setInitialised(true);
    notifyListeners();
  }

  String formatSleepDuration(Duration duration) {
    return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
  }

  Future _getSleepInfo() async {
    _dailySleepStats = {};
    _chartSleepStages.clear();
    _sleepStageAverages.clear();
    _daySleepStages.clear();

    // Get 8 days worth to account for last night.
    int daysToGet = 8;
    if (_weekStartDate.day == findFirstDateOfTheWeek(DateTime.now()).day) {
      daysToGet++;
    }
    _healthDataPoints = await _healthConnectManager.getSleepSessionData(
        startDate: _weekStartDate, days: daysToGet);
    if (_healthDataPoints?.isEmpty ?? true) {
      _sleepResultType = SleepResultType.noData;
    } else {
      _sleepResultType = SleepResultType.sleepTimeOnly;
      Map<DateTime, List<HealthDataPoint>?> datedHealthDataPoints =
          SleepScreenViewModel.getDatedHealthData(_healthDataPoints!);
      datedHealthDataPoints.removeWhere((key, value) => key.isAfter(_weekEndDate) ||
          key.isBefore(_weekStartDate));

      for (DateTime sleepDay in datedHealthDataPoints.keys) {
        _dailySleepStats[sleepDay] = SleepScreenViewModel.getDaySleepStats(
            datedHealthDataPoints[sleepDay]!);
      }

      for (DateTime dateTime in _dailySleepStats.keys) {
        if (_dailySleepStats[dateTime]!.resultType == SleepResultType.sleepStaging) {
          _sleepResultType = SleepResultType.sleepStaging;
        }
        if (_dailySleepStats[dateTime]!.resultType != SleepResultType.noData) {
          _chartSleepStages[dateTime] = SleepScreenViewModel.getChartSleepStagesFromDayStats(
              _dailySleepStats[dateTime]!);
        }
        int totalSleepLatency = 0;
        int sleepLatencyDays = 0;
        if (_dailySleepStats[dateTime]!.sleepLatency != null) {
          totalSleepLatency += _dailySleepStats[dateTime]!.sleepLatency!.inMinutes;
          sleepLatencyDays++;
        }
        if (sleepLatencyDays != 0) {
          _averageSleepLatency = Duration(minutes: totalSleepLatency ~/ sleepLatencyDays);
        }
      }

      for (LucidSleepStage lucidSleepStage in LucidSleepStage.values) {
        _sleepStageAverages[lucidSleepStage] = SleepScreenViewModel.getAverageForStage(
            lucidSleepStage, _chartSleepStages);
      }

      // Get sleep stages for each day for bar chart.
      for (DateTime dateTime in _dailySleepStats.keys) {
        if (_dailySleepStats[dateTime]!.resultType == SleepResultType.noData) {
          continue;
        } else if (_dailySleepStats[dateTime]!.resultType == SleepResultType.sleepTimeOnly) {
          if (_daySleepStages[LucidSleepStage.sleeping] == null) {
            _daySleepStages[LucidSleepStage.sleeping] = [];
          }
          _daySleepStages[LucidSleepStage.sleeping]!.add(DaySleepStage(
              dayOfWeekIndex: dateTime.weekday == 7 ? 0 : dateTime.weekday,
              dayOfWeek: dateTime.dayOfWeek,
              lucidSleepStage: LucidSleepStage.sleeping.getLabel(),
              durationMinutes: _dailySleepStats[dateTime]!.stageDurations[LucidSleepStage.sleeping]!
                  .inMinutes,
              color: LucidSleepStage.sleeping.getColor()));
          continue;
        } else {
          for (LucidSleepStage lucidSleepStage in chartedStages) {
            if (_daySleepStages[lucidSleepStage] == null) {
              _daySleepStages[lucidSleepStage] = [];
            }
            _daySleepStages[lucidSleepStage]!.add(DaySleepStage(
                dayOfWeekIndex: dateTime.weekday == 7 ? 0 : dateTime.weekday,
                dayOfWeek: dateTime.dayOfWeek,
                lucidSleepStage: lucidSleepStage.getLabel(),
                durationMinutes: _dailySleepStats[dateTime]!.stageDurations[lucidSleepStage]!
                    .inMinutes,
                color: lucidSleepStage.getColor()));
          }
        }
      }
    }
  }

  void changeDay(int relativeDayChange) async {
    if (relativeDayChange > 0) {
      _weekStartDate = _weekStartDate.add(Duration(days: relativeDayChange));
      _weekEndDate = _weekEndDate.add(Duration(days: relativeDayChange));
    } else if (relativeDayChange < 0) {
      _weekStartDate = _weekStartDate.subtract(Duration(days: -relativeDayChange));
      _weekEndDate = _weekEndDate.subtract(Duration(days: -relativeDayChange));
    } else {
      return;
    }
    await _getSleepInfo();
    notifyListeners();
  }
}