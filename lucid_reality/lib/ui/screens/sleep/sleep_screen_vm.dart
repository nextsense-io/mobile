import 'package:flutter/material.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class SleepScreenViewModel extends ViewModel {

  void init() async {
    setInitialised(true);
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