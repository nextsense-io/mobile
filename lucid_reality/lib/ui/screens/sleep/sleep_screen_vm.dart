import 'package:flutter/material.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:health/health.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

enum SleepResultType {
  notInstalled,
  sleepTimeOnly,
  sleepStaging,
  noData
}

class SleepScreenViewModel extends ViewModel {

  void init() async {
    setInitialised(true);
  }

  static Map<DateTime, List<SleepStage>?> getDatedSleepSessionFromHealthData(
      List<HealthDataPoint> healthData) {
    Map<DateTime, List<SleepStage>?> datedSleepStages = {};
    for (HealthDataPoint dataPoint in healthData) {
      if (dataPoint.type == HealthDataType.SLEEP_SESSION &&
          dataPoint.unit == HealthDataUnit.MINUTE) {
        if (datedSleepStages[dataPoint.dateFrom] == null) {
          datedSleepStages[dataPoint.dateFrom] = [];
        }
        datedSleepStages[dataPoint.dateFrom]!.add(
            SleepStage(LucidSleepStage.sleeping.getLabel(), 100,
                Duration(minutes: int.parse(dataPoint.value.toString())),
                LucidSleepStage.sleeping.getColor()));
      }
    }
    return datedSleepStages;
  }
}

extension LucidSleepStageToColorValue on LucidSleepStage {
  Color getColor() {
    switch (this) {
      case LucidSleepStage.core:
        return NextSenseColors.coral;
      case LucidSleepStage.deep:
        return NextSenseColors.skyBlue;
      case LucidSleepStage.rem:
        return NextSenseColors.royalBlue;
      case LucidSleepStage.awake:
        return NextSenseColors.royalPurple;
      case LucidSleepStage.sleeping:
        return NextSenseColors.coral;
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