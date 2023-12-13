import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test_data_provider.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/pvt_manager.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_list_screen.dart';

class PsychomotorVigilanceTestViewModule extends ViewModel {
  final PsychomotorVigilanceTestDataProvider psychomotorVigilanceTestDataProvider =
      getIt<PsychomotorVigilanceTestDataProvider>();
  final AuthManager _authManager = getIt<AuthManager>();
  final PVTManager pvtManager = getIt<PVTManager>();
  final Navigation _navigation = getIt<Navigation>();
  late ValueNotifier<PsychomotorVigilanceTestStages> page;
  final Random random = Random();
  ValueNotifier<bool>? btnVisibility;
  PsychomotorVigilanceTest? psychomotorVigilanceTest;

  PsychomotorVigilanceTestViewModule(this.page);

  @override
  void init() async {
    super.init();
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      await pvtManager.fetchPVTResults();
      notifyListeners();
    }
  }

  void redirectToPVTMain() {
    psychomotorVigilanceTest = null;
    page.value = PsychomotorVigilanceTestStages.pvtMain;
  }

  void navigateToPVT() {
    page.value = PsychomotorVigilanceTestStages.pvt;
  }

  void navigateToPVTResultsPage() async {
    if (psychomotorVigilanceTest != null) {
      psychomotorVigilanceTestDataProvider.add(psychomotorVigilanceTest!);
      psychomotorVigilanceTestDataProvider.generateReport(psychomotorVigilanceTest!);
      await pvtManager.addPVTResult(psychomotorVigilanceTest!.toPVTResult());
    }
    page.value = PsychomotorVigilanceTestStages.pvtResults;
  }

  void navigateToPVTResultsWithData(PsychomotorVigilanceTest psychomotorVigilanceTest) {
    psychomotorVigilanceTestDataProvider.generateReport(psychomotorVigilanceTest);
    page.value = PsychomotorVigilanceTestStages.pvtResults;
  }

  void scheduleButtonVisibility() {
    psychomotorVigilanceTest ??= PsychomotorVigilanceTest.getInstance(DateTime.now());
    Future.delayed(
      Duration(seconds: random.nextInt(5) + 1),
      () {
        psychomotorVigilanceTest?.taps.add(TapTime.getInstance(DateTime.now()));
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
