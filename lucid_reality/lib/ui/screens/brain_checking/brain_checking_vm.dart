import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/brain_checking.dart';
import 'package:lucid_reality/domain/brain_checking_data_provider.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

import 'brain_checking_tab_screen.dart';

class BrainCheckingViewModule extends ViewModel {
  final BrainCheckingDataProvider brainCheckingDataProvider = getIt<BrainCheckingDataProvider>();
  final Navigation _navigation = getIt<Navigation>();
  late ValueNotifier<BrainCheckingStages> page;
  final Random random = Random();
  ValueNotifier<bool>? btnVisibility;
  BrainChecking? brainChecking;

  BrainCheckingViewModule(this.page);

  void redirectToBrainCheckingTab() {
    brainChecking = null;
    page.value = BrainCheckingStages.brainCheckingMain;
  }

  void navigateToBrainChecking() {
    page.value = BrainCheckingStages.brainChecking;
  }

  void navigateToBrainCheckingResultsPage() {
    if (brainChecking != null) {
      brainCheckingDataProvider.add(brainChecking!);
      brainCheckingDataProvider.generateReport(brainChecking!);
    }
    page.value = BrainCheckingStages.brainCheckingResults;
  }

  void navigateToBrainCheckingResultsPageWithData(BrainChecking brainChecking) {
    brainCheckingDataProvider.generateReport(brainChecking);
    page.value = BrainCheckingStages.brainCheckingResults;
  }

  void scheduleButtonVisibility() {
    brainChecking ??= BrainChecking.instance(DateTime.now());
    Future.delayed(
      Duration(seconds: random.nextInt(5) + 1),
      () {
        brainChecking?.taps.add(TapTime(startTime: DateTime.now()));
        btnVisibility?.value = true;
      },
    );
  }

  void rescheduleButtonVisibility() {
    brainChecking?.taps.lastOrNull?.endTime = DateTime.now();
    btnVisibility?.value = false;
    scheduleButtonVisibility();
  }
}
