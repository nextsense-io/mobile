import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';

import 'reality_check_completion_screen.dart';

class RealityCheckBedtimeScreenViewModel extends RealityCheckBaseViewModel {
  void navigateToRealityCheckCompletionScreen(
      {required DateTime bedtime, required DateTime wakeUpTime}) {
    lucidManager.saveBedtime(bedtime.millisecondsSinceEpoch, wakeUpTime.millisecondsSinceEpoch);
    navigation.navigateTo(RealityCheckCompletionScreen.id, replace: true);
  }
}
