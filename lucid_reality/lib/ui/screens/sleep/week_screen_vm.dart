import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:health/health.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/managers/health_connect_manager.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';

class WeekScreenViewModel extends ViewModel {
  final _healthConnectManager = getIt<HealthConnectManager>();
  List<HealthDataPoint>? _healthDataPoints;
  DateTime _currentDate = DateTime.now().dateNoTime;
  DateTime _weekStartDate = DateTime.now().dateNoTime.subtract(Duration(days: 7));
  SleepResultType _sleepResultType = SleepResultType.noData;
  Map<DateTime, List<SleepStage>> _sleepStages = {};
  Map<LucidSleepStage, Duration> _sleepStageAverages = {};
  Duration? _averageSleepTime;

  DateTime get currentDate => _currentDate;
  String get weekDateRange  {
    if (_weekStartDate.month == _currentDate.month) {
      return "${_weekStartDate.monthDay}-${_currentDate.day}, ${_currentDate.year}";
    }
    return "${_weekStartDate.monthDay}-${_currentDate.monthDay}, ${_currentDate.year}";
  }
  SleepResultType get sleepResultType => _sleepResultType;
  Map<LucidSleepStage, Duration> get sleepStageAverages => _sleepStageAverages;
  Map<DateTime, List<SleepStage>> get sleepStages => _sleepStages;
  Duration get averageSleepTime => _averageSleepTime ?? Duration.zero;

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
    _averageSleepTime = Duration.zero;
    _sleepStageAverages.clear();

    _healthDataPoints = await _healthConnectManager.getSleepSessionData(
        startDate: currentDate.subtract(Duration(days: 7)), days: 7);
    if (_healthDataPoints?.isEmpty ?? true) {
      _sleepResultType = SleepResultType.noData;
    } else {
      _sleepResultType = SleepResultType.sleepStaging;
      // TODO: parse sleep staging data
      Map<DateTime, List<SleepStage>?> datedSleepStages =
          SleepScreenViewModel.getDatedSleepSessionFromHealthData(_healthDataPoints!);
      _averageSleepTime = getAverageForStage(LucidSleepStage.sleeping, datedSleepStages);
      for (LucidSleepStage lucidSleepStage in LucidSleepStage.values) {
        _sleepStageAverages[lucidSleepStage] = getAverageForStage(lucidSleepStage, datedSleepStages);
      }
    }
  }

  Duration getAverageForStage(LucidSleepStage stage,
      Map<DateTime, List<SleepStage>?> datedSleepStages) {
    int totalStageTime = 0;
    int stageDays = 0;
    for (List<SleepStage>? sleepStage in datedSleepStages.values) {
      if (sleepStage != null ) {
        totalStageTime += sleepStage[0].duration.inMinutes;
        stageDays++;
      }
    }
    return Duration(minutes: totalStageTime ~/ stageDays);
  }

  void changeDay(int relativeDayChange) async {
    if (relativeDayChange > 0) {
      _currentDate = _currentDate.add(Duration(days: relativeDayChange));
      _weekStartDate = _weekStartDate.add(Duration(days: relativeDayChange));
    } else if (relativeDayChange < 0) {
      _currentDate = _currentDate.subtract(Duration(days: -relativeDayChange));
      _weekStartDate = _weekStartDate.subtract(Duration(days: -relativeDayChange));
    } else {
      return;
    }
    await _getSleepInfo();
    notifyListeners();
  }
}