import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/pvt_manager.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_list_screen.dart';

class PsychomotorVigilanceTestViewModule extends ViewModel {
  final AuthManager _authManager = getIt<AuthManager>();
  final PVTManager pvtManager = getIt<PVTManager>();
  final Navigation _navigation = getIt<Navigation>();
  late ValueNotifier<PsychomotorVigilanceTestStages> page;
  final Random random = Random();
  ValueNotifier<bool>? btnVisibility;
  PsychomotorVigilanceTest? psychomotorVigilanceTest;
  TapTime? tapTime;

  PsychomotorVigilanceTestViewModule(this.page);

  @override
  void init() async {
    super.init();
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      await pvtManager.fetchPVTResults();
      setInitialised(true);
      notifyListeners();
    }
  }

  void redirectToPVTMain() {
    psychomotorVigilanceTest = null;
    tapTime = null;
    page.value = PsychomotorVigilanceTestStages.pvtMain;
  }

  void navigateToPVT() {
    page.value = PsychomotorVigilanceTestStages.pvt;
  }

  void navigateToPVTResultsPage() async {
    if (psychomotorVigilanceTest != null) {
      pvtManager.add(psychomotorVigilanceTest!);
      pvtManager.generateReport(psychomotorVigilanceTest!);
    }
    page.value = PsychomotorVigilanceTestStages.pvtResults;
  }

  void navigateToPVTResultsWithData(PsychomotorVigilanceTest psychomotorVigilanceTest) {
    this.psychomotorVigilanceTest = psychomotorVigilanceTest;
    pvtManager.generateReport(psychomotorVigilanceTest);
    page.value = PsychomotorVigilanceTestStages.pvtResults;
  }

  void scheduleButtonVisibility() {
    psychomotorVigilanceTest ??= PsychomotorVigilanceTest.getInstance(DateTime.now());
    Future.delayed(
      Duration(seconds: random.nextInt(5) + 1),
      () {
        btnVisibility?.value = true;
        tapTime = TapTime.getInstance(DateTime.now());
      },
    );
  }

  void rescheduleButtonVisibility() {
    btnVisibility?.value = false;
    tapTime?.endTime = DateTime.now();
    psychomotorVigilanceTest?.taps.add(tapTime?.getTapLatency() ?? 0);
    scheduleButtonVisibility();
  }
}
