import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/sleep_staging_manager.dart';
import 'package:nextsense_consumer_ui/ui/components/sleep_pie_chart.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen_vm.dart';

class SleepProtocolsViewModel extends ProtocolScreenViewModel {

  final SleepStagingManager _sleepStagingManager = getIt<SleepStagingManager>();
  final _logger = Logger('SleepProtocolScreenViewModel');

  SleepProtocolsViewModel(protocol) : super(protocol);

  @override
  Future<bool> startSession() async {
    bool started = await super.startSession();
    if (!started) {
      return false;
    }
    _sleepStagingManager.startSleepStaging();
    return true;
  }

  List<SleepStage> getSleepStages() {
    _logger.log(Level.INFO, "Getting sleep stages.");
    if (_sleepStagingManager.sleepStagingLabels.isEmpty) {
      return [];
    }
    Map<SleepStagingResult, int> sleepStageCounts = {};
    Map<SleepStagingResult, Duration> sleepStageDurations = {};
    for (SleepStagingResult sleepStagingResult in SleepStagingResult.values) {
      sleepStageCounts[sleepStagingResult] = 0;
      sleepStageDurations[sleepStagingResult] = Duration.zero;
    }
    for (String sleepStageLabel in _sleepStagingManager.sleepStagingLabels) {
      final sleepStagingResult = SleepStagingResult.fromString(sleepStageLabel);
      sleepStageCounts[sleepStagingResult] = sleepStageCounts[sleepStagingResult]! + 1;
      sleepStageDurations[sleepStagingResult] = sleepStageDurations[sleepStagingResult]! +
          const Duration(seconds: 30);
    }
    List<SleepStage> sleepStages = [];
    for (SleepStagingResult sleepStagingResult in SleepStagingResult.values) {
      sleepStages.add(SleepStage(sleepStagingResult.name.toLowerCase(),
          ((sleepStageCounts[sleepStagingResult]! /
              _sleepStagingManager.sleepStagingLabels.length) * 100).round(),
          sleepStageDurations[sleepStagingResult]!));
    }
    return sleepStages;
  }

  @override
  Future stopSession() async {
    await super.stopSession();
    _sleepStagingManager.stopSleepStaging();
  }

  String formatDuration(Duration duration) {
    if (duration.inMinutes == 0) {
      if (duration.inSeconds.remainder(60) == 0) {
        return "0m";
      }
      return "${duration.inSeconds.remainder(60)}s";
    }
    if (duration.inSeconds.remainder(60) == 0) {
      return "${duration.inMinutes}m";
    }
    return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
  }
}