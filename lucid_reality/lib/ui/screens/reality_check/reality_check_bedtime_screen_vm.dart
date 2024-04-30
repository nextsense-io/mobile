import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';

import 'reality_check_completion_screen.dart';

class RealityCheckBedtimeScreenViewModel extends RealityCheckBaseViewModel {
  final CustomLogPrinter _logger = CustomLogPrinter('RealityCheckBedtimeScreenViewModel');

  void navigateToRealityCheckCompletionScreen() async {
    navigation.navigateTo(RealityCheckCompletionScreen.id, replace: true);
  }

  Future<void> saveBedtime({required DateTime bedtime, required DateTime wakeUpTime}) async {
    try {
      setBusy(true);
      await lucidManager.saveBedtime(bedtime.millisecondsSinceEpoch, wakeUpTime.millisecondsSinceEpoch);
      await scheduleNewToneNotifications(
          lucidManager.realityCheck.getRealityTest()?.getTotemSound() ?? 'air');
    } catch (e) {
      _logger.log(Level.WARNING, e);
    } finally {
      setBusy(false);
    }
  }
}
