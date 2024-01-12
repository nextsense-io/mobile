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
  DaySleepStats? _daySleepStats;
  Duration _totalSleepTime = Duration.zero;
  DateTime? _sleepStartTime;
  DateTime? _sleepEndTime;
  List<ChartSleepStage> _chartSleepStages = [];

  bool get healthAppInstalled => _healthAppInstalled ?? false;
  bool get healthAppAuthorized => _healthAppAuthorized ?? false;
  DateTime get currentDate => _currentDate;
  SleepResultType get sleepResultType => _daySleepStats?.resultType ?? SleepResultType.noData;
  String get totalSleepTime => _totalSleepTime == Duration.zero ? "N/A"
      : "${_totalSleepTime.hhmm}";
  String get sleepStartEndTime => _sleepStartTime == null ? "No sleep data"
      : "${_sleepStartTime!.hmma} - ${_sleepEndTime!.hmma}";
  String get sleepLatency => _daySleepStats?.sleepLatency == null ? "N/A"
      : "${_daySleepStats!.sleepLatency!.hhmm}";
  List<ChartSleepStage> get chartSleepStages => _chartSleepStages.where(
          (element) => element.stage.compareTo(LucidSleepStage.sleeping.getLabel()) != 0).toList();

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

  Future _getSleepInfo() async {
    _healthDataPoints = await _healthConnectManager.getSleepSessionData(
        startDate: currentDate, days: 1);
    _chartSleepStages.clear();
    _totalSleepTime = Duration.zero;
    _sleepStartTime = null;
    _sleepEndTime = null;
    _daySleepStats = SleepScreenViewModel.getDaySleepStats(_healthDataPoints!);

    if (_daySleepStats!.resultType != SleepResultType.noData) {
      _chartSleepStages = SleepScreenViewModel.getChartSleepStagesFromDayStats(_daySleepStats!);
    }

    // Get total time for all sleep stages.
    _totalSleepTime = _daySleepStats?.stageDurations[LucidSleepStage.sleeping] ?? Duration.zero;
    _sleepStartTime = _daySleepStats?.startTime;
    _sleepEndTime = _daySleepStats?.endTime;
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