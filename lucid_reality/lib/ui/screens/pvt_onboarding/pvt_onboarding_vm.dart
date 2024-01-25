import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class PVTOnboardingViewModel extends ViewModel {
  final Navigation navigation = getIt<Navigation>();
  final pvtReport = <PsychomotorVigilanceTestReport>[];
  final pvtResults = <PsychomotorVigilanceTest>[];

  @override
  void init() {
    super.init();
    prepareDummyData();
  }

  void prepareDummyData() {
    // Report dummy data
    pvtReport.add(
        PsychomotorVigilanceTestReport('Average response time', 303, NextSenseColors.royalPurple));
    pvtReport.add(PsychomotorVigilanceTestReport('Fastest response', 262, NextSenseColors.skyBlue));
    pvtReport.add(PsychomotorVigilanceTestReport('Slowest response', 395, NextSenseColors.coral));

    // Dummy pvt results
    pvtResults.add(
      PsychomotorVigilanceTest(
        'Alert',
        323,
        DateTime(
          2023,
          10,
          8,
          9,
          5,
        ),
        Alertness.alert,
      ),
    );
    pvtResults.add(
      PsychomotorVigilanceTest(
        'Highly alert',
        291,
        DateTime(
          2023,
          10,
          7,
          8,
          35,
        ),
        Alertness.highlyAlert,
      ),
    );
    pvtResults.add(
      PsychomotorVigilanceTest(
        'Drowsy',
        415,
        DateTime(
          2023,
          10,
          7,
          8,
          35,
        ),
        Alertness.drowsy,
      ),
    );
    notifyListeners();
  }

  void navigateToPVTScreen() {
    navigation.pop();
  }
}
