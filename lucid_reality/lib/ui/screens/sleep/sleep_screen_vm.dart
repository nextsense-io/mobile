import 'package:flutter/material.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:health/health.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/date_utils.dart';

enum SleepResultType {
  notInstalled,
  sleepTimeOnly,
  sleepStaging,
  noData
}

// Order matters as this is how they are shown in the UI.
const List<LucidSleepStage> chartedStages = [
  LucidSleepStage.core,
  LucidSleepStage.deep,
  LucidSleepStage.rem,
  LucidSleepStage.awake
];

// Cutoff time when sleep data is considered to be from the previous day. Could also be based on
// sleep schedule or contiguous sleep segments.
const _sleepCutoffTime = TimeOfDay(hour: 16, minute: 0);

class DaySleepStats {
  final SleepResultType resultType;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<LucidSleepStage, Duration> stageDurations;

  DaySleepStats({required this.resultType, required this.startTime, required this.endTime,
    required this.stageDurations});
}

class SleepScreenViewModel extends ViewModel {

  void init() async {
    setInitialised(true);
  }

  static Map<DateTime, List<HealthDataPoint>?> getDatedHealthData(
      List<HealthDataPoint> healthData) {
    Map<DateTime, List<HealthDataPoint>?> datedHealthData = {};
    for (HealthDataPoint dataPoint in healthData) {
      DateTime sleepSessionDate = dataPoint.dateFrom;
      if (TimeOfDay.fromDateTime(dataPoint.dateFrom).compareTo(_sleepCutoffTime) < 0) {
        sleepSessionDate = dataPoint.dateFrom.subtract(Duration(days: 1));
      }
      if (datedHealthData[sleepSessionDate.dateNoTime] == null) {
        datedHealthData[sleepSessionDate.dateNoTime] = [];
      }
      datedHealthData[sleepSessionDate.dateNoTime]!.add(dataPoint);
    }
    return datedHealthData;
  }

  static Duration getAverageForStage(LucidSleepStage stage,
      Map<DateTime, List<ChartSleepStage>?> datedSleepStages) {
    int totalStageTime = 0;
    int stageDays = 0;
    for (List<ChartSleepStage>? chartSleepStages in datedSleepStages.values) {
      if (chartSleepStages == null) {
        continue;
      }
      for (ChartSleepStage chartSleepStage in chartSleepStages) {
        if (chartSleepStage.stage == stage.getLabel()) {
          totalStageTime += chartSleepStage.duration.inMinutes;
          stageDays++;
          break;
        }
      }
    }
    if (stageDays == 0 || totalStageTime == 0) {
      return Duration.zero;
    }
    return Duration(minutes: totalStageTime ~/ stageDays);
  }

  static DaySleepStats getDaySleepStats(List<HealthDataPoint> dataPoints) {
    SleepResultType sleepResultType = SleepResultType.noData;
    Map<LucidSleepStage, Duration> sleepStageDurations = {};
    for (LucidSleepStage lucidSleepStage in LucidSleepStage.values) {
      sleepStageDurations[lucidSleepStage] = Duration.zero;
    }
    DateTime? sleepStartTime;
    DateTime? sleepEndTime;

    // Get total duration for each sleep stage in that sleep.
    for (HealthDataPoint dataPoint in dataPoints) {
      if (dataPoint.unit == HealthDataUnit.MINUTE) {
        LucidSleepStage lucidSleepStage = getSleepStageFromHealthDataPoint(dataPoint);
        sleepStageDurations[lucidSleepStage] = sleepStageDurations[lucidSleepStage]! +
            Duration(minutes: int.parse(dataPoint.value.toString()));
        if (chartedStages.contains(lucidSleepStage)) {
          if (sleepStartTime == null || sleepStartTime.isAfter(dataPoint.dateFrom)) {
            sleepStartTime = dataPoint.dateFrom;
          }
          if (sleepEndTime == null || sleepEndTime.isBefore(dataPoint.dateTo)) {
            sleepEndTime = dataPoint.dateTo;
          }
        }
      } else {
        print("Health data point ${dataPoint.type} unit is not minutes");
      }
    }

    // Check if any stage data is present.
    for (LucidSleepStage lucidSleepStage in chartedStages) {
      if (sleepStageDurations[lucidSleepStage] != Duration.zero) {
        sleepResultType = SleepResultType.sleepStaging;
        break;
      }
    }
    if (sleepResultType != SleepResultType.sleepStaging) {
      // Check if at least total sleep time is present.
      if (sleepStageDurations[LucidSleepStage.sleeping] != Duration.zero) {
        sleepResultType = SleepResultType.sleepTimeOnly;
      }
    } else if (sleepStageDurations[LucidSleepStage.sleeping] == Duration.zero) {
      // In case total sleep time is not present in the data.
      Duration totalSleepTime = Duration.zero;
      for (LucidSleepStage lucidSleepStage in chartedStages) {
        totalSleepTime += sleepStageDurations[lucidSleepStage]!;
      }
      sleepStageDurations[LucidSleepStage.sleeping] = totalSleepTime;
    }

    return DaySleepStats(resultType: sleepResultType, startTime: sleepStartTime,
        endTime: sleepEndTime, stageDurations: sleepStageDurations);
  }

  static List<ChartSleepStage> getSleepStagesFromDayStats(DaySleepStats sleepStats) {
    List<ChartSleepStage> chartSleepStages = [];
    for (LucidSleepStage lucidSleepStage in LucidSleepStage.values) {
      Duration totalSleepTime = sleepStats.stageDurations[lucidSleepStage]!;
      int percentage = 0;
      if (totalSleepTime != Duration.zero) {
        percentage = (sleepStats.stageDurations[lucidSleepStage]!.inMinutes /
            totalSleepTime.inMinutes * 100).round();
      }
      chartSleepStages.add(ChartSleepStage(lucidSleepStage.getLabel(), percentage,
          sleepStats.stageDurations[lucidSleepStage]!, lucidSleepStage.getColor()));
    }
    return chartSleepStages;
  }
}

extension LucidSleepStageToValues on LucidSleepStage {
  Color getColor() {
    switch (this) {
      case LucidSleepStage.core:
        return NextSenseColors.royalBlue;
      case LucidSleepStage.deep:
        return NextSenseColors.skyBlue;
      case LucidSleepStage.rem:
        return NextSenseColors.coral;
      case LucidSleepStage.awake:
        return NextSenseColors.royalPurple;
      case LucidSleepStage.sleeping:
        return NextSenseColors.royalBlue;
    }
  }

  String getLabel() {
    switch (this) {
      case LucidSleepStage.core:
        return "Core";
      case LucidSleepStage.deep:
        return "Deep";
      case LucidSleepStage.rem:
        return "REM";
      case LucidSleepStage.awake:
        return "Awake";
      case LucidSleepStage.sleeping:
        return "Sleeping";
    }
  }
}

LucidSleepStage getSleepStageFromHealthDataPoint(HealthDataPoint dataPoint) {
  switch (dataPoint.type) {
    case HealthDataType.SLEEP_IN_BED:
      return LucidSleepStage.sleeping;
    case HealthDataType.SLEEP_ASLEEP:
      return LucidSleepStage.sleeping;
    case HealthDataType.SLEEP_AWAKE:
      return LucidSleepStage.awake;
    case HealthDataType.SLEEP_DEEP:
      return LucidSleepStage.deep;
    case HealthDataType.SLEEP_LIGHT:
      return LucidSleepStage.core;
    case HealthDataType.SLEEP_REM:
      return LucidSleepStage.rem;
    case HealthDataType.SLEEP_OUT_OF_BED:
      return LucidSleepStage.awake;
    case HealthDataType.SLEEP_SESSION:
      return LucidSleepStage.sleeping;
    default:
      return LucidSleepStage.awake;
  }
}