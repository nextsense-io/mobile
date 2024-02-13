import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:health/health.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/managers/health_connect_manager.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';

enum SleepResultType {
  sleepTimeOnly,
  sleepStaging,
  noData
}

class DayScreenViewModel extends ViewModel {
  final _healthConnectManager = getIt<HealthConnectManager>();
  List<HealthDataPoint>? _healthDataPoints;
  DateTime _currentDate = DateTime.now().dateNoTime;
  SleepResultType _sleepResultType = SleepResultType.noData;
  Duration _totalSleepTime = Duration.zero;
  DateTime? _sleepStartTime;
  DateTime? _sleepEndTime;
  List<SleepStage> _sleepStages = [];

  DateTime get currentDate => _currentDate;
  SleepResultType get sleepResultType => _sleepResultType;
  String get totalSleepTime => _totalSleepTime == Duration.zero ? "N/A" :
      "${_totalSleepTime.inHours}h ${_totalSleepTime.inMinutes.remainder(60)}m";
  String get sleepStartEndTime => _sleepStartTime == null ? "No sleep data" :
      "${_sleepStartTime!.hmma} - ${_sleepEndTime!.hmma}";
  List<SleepStage> get sleepStages => _sleepStages;

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
    _healthDataPoints = await _healthConnectManager.getSleepSessionData(
        startDate: currentDate, days: 1);
    if (_healthDataPoints?.isEmpty ?? true) {
      _sleepResultType = SleepResultType.noData;
      _totalSleepTime = Duration.zero;
      _sleepStartTime = null;
      _sleepEndTime = null;
      _sleepStages.clear();
    } else if (_healthDataPoints!.length == 1 && _healthDataPoints![0].type ==
        HealthDataType.SLEEP_SESSION && _healthDataPoints![0].unit == HealthDataUnit.MINUTE) {
      _sleepResultType = SleepResultType.sleepTimeOnly;
      _totalSleepTime = Duration(minutes: int.parse(_healthDataPoints![0].value.toString()));
      _sleepStartTime = _healthDataPoints![0].dateFrom;
      _sleepEndTime = _healthDataPoints![0].dateTo;
      _sleepStages = [
        SleepStage(LucidSleepStage.sleeping.getLabel(), 100, _totalSleepTime,
            LucidSleepStage.sleeping.getColor())];
    } else {
      // TODO: parse sleep staging data
      _sleepResultType = SleepResultType.sleepStaging;
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