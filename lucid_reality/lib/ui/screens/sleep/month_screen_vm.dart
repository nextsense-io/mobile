import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:health/health.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/managers/health_connect_manager.dart';
import 'package:lucid_reality/ui/components/sleep_bar_chart.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:quiver/time.dart';

class MonthScreenViewModel extends ViewModel {
  final _healthConnectManager = getIt<HealthConnectManager>();

  List<HealthDataPoint>? _healthDataPoints;
  DateTime _monthStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1).dateNoTime;
  SleepResultType _sleepResultType = SleepResultType.noData;
  Map<DateTime, DaySleepStats> _dailySleepStats = {};
  Map<DateTime, List<ChartSleepStage>> _chartSleepStages = {};
  Map<LucidSleepStage, Duration> _sleepStageAverages = {};
  Map<LucidSleepStage, List<DaySleepStage>> _daySleepStages = {};
  Duration? _averageSleepLatency;
  DateTime get currentMonth => _monthStartDate;
  String get monthYear {
    return "${_monthStartDate.monthString} ${_monthStartDate.year}";
  }
  SleepResultType get sleepResultType => _sleepResultType;
  Map<LucidSleepStage, Duration> get sleepStageAverages => _sleepStageAverages;
  Map<DateTime, List<ChartSleepStage>> get chartSleepStages => _chartSleepStages;
  List<DaySleepStage> get daySleepStages => _daySleepStages.values.expand((x) => x).toList();
  Duration get averageSleepTime => _sleepStageAverages[LucidSleepStage.sleeping] ?? Duration.zero;
  Duration? get averageSleepLatency => _averageSleepLatency;

  void init() async {
    await _healthConnectManager.authorize();
    await _getSleepInfo();
    setInitialised(true);
    notifyListeners();
  }

  String formatSleepDuration(Duration duration) {
    return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
  }

  Future _getSleepInfo() async {
    _sleepStageAverages.clear();
    int daysInMonthInt = daysInMonth(_monthStartDate.year, _monthStartDate.month);
    _healthDataPoints = await _healthConnectManager.getSleepSessionData(
        startDate: currentMonth, days: daysInMonthInt);
    if (_healthDataPoints?.isEmpty ?? true) {
      _sleepResultType = SleepResultType.noData;
    } else {
      _sleepResultType = SleepResultType.sleepTimeOnly;
      Map<DateTime, List<HealthDataPoint>?> datedHealthDataPoints =
          SleepScreenViewModel.getDatedHealthData(_healthDataPoints!);

      _dailySleepStats = {};
      for (DateTime sleepDay in datedHealthDataPoints.keys) {
        _dailySleepStats[sleepDay] =
            SleepScreenViewModel.getDaySleepStats(datedHealthDataPoints[sleepDay]!);
      }

      for (DateTime dateTime in _dailySleepStats.keys) {
        if (_dailySleepStats[dateTime]!.resultType == SleepResultType.sleepStaging) {
          _sleepResultType = SleepResultType.sleepStaging;
        }
        if (_dailySleepStats[dateTime]!.resultType != SleepResultType.noData) {
          _chartSleepStages[dateTime] =
              SleepScreenViewModel.getChartSleepStagesFromDayStats(_dailySleepStats[dateTime]!);
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
        _sleepStageAverages[lucidSleepStage] =
            SleepScreenViewModel.getAverageForStage(lucidSleepStage, _chartSleepStages);
      }
      // TODO: Calculate any needed stats for the UI.
    }
  }

  void changeMonth(int relativeMonthChange) async {
    // TODO: Change to next/previous month.
    if (relativeMonthChange > 0) {
      _monthStartDate = _monthStartDate.addMonths(relativeMonthChange);
    } else if (relativeMonthChange < 0) {
      _monthStartDate = _monthStartDate.subtractMonths(relativeMonthChange);
    } else {
      return;
    }
    print('current month=>${_monthStartDate.getDate()}');
    await _getSleepInfo();
    notifyListeners();
  }
}
