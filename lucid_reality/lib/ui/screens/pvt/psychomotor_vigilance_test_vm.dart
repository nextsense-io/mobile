import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test_data_provider.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_list_screen.dart';

class PsychomotorVigilanceTestViewModule extends ViewModel {
  final PsychomotorVigilanceTestDataProvider brainCheckingDataProvider =
      getIt<PsychomotorVigilanceTestDataProvider>();
  final Navigation _navigation = getIt<Navigation>();
  late ValueNotifier<PsychomotorVigilanceTestStages> page;
  final Random random = Random();
  ValueNotifier<bool>? btnVisibility;
  PsychomotorVigilanceTest? psychomotorVigilanceTest;

  PsychomotorVigilanceTestViewModule(this.page);

  void redirectToPVTMain() {
    psychomotorVigilanceTest = null;
    page.value = PsychomotorVigilanceTestStages.pvtMain;
  }

  void navigateToPVT() {
    page.value = PsychomotorVigilanceTestStages.pvt;
  }

  void navigateToPVTResultsPage() {
    if (psychomotorVigilanceTest != null) {
      brainCheckingDataProvider.add(psychomotorVigilanceTest!);
      brainCheckingDataProvider.generateReport(psychomotorVigilanceTest!);
    }
    page.value = PsychomotorVigilanceTestStages.pvtResults;
  }

  void navigateToPVTResultsWithData(PsychomotorVigilanceTest psychomotorVigilanceTest) {
    brainCheckingDataProvider.generateReport(psychomotorVigilanceTest);
    page.value = PsychomotorVigilanceTestStages.pvtResults;
  }

  void scheduleButtonVisibility() {
    psychomotorVigilanceTest ??= PsychomotorVigilanceTest.instance(DateTime.now());
    Future.delayed(
      Duration(seconds: random.nextInt(5) + 1),
      () {
        psychomotorVigilanceTest?.taps.add(TapTime(startTime: DateTime.now()));
        btnVisibility?.value = true;
      },
    );
  }

  void rescheduleButtonVisibility() {
    psychomotorVigilanceTest?.taps.lastOrNull?.endTime = DateTime.now();
    btnVisibility?.value = false;
    scheduleButtonVisibility();
  }
}
