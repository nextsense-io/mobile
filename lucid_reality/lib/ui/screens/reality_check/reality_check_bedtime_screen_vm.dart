import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/utils/notification.dart';

import 'reality_check_completion_screen.dart';

class RealityCheckBedtimeScreenViewModel extends RealityCheckBaseViewModel {
  final CustomLogPrinter _logger = CustomLogPrinter('RealityCheckBedtimeScreenViewModel');

  void navigateToRealityCheckCompletionScreen() async {
    navigation.navigateTo(RealityCheckCompletionScreen.id, replace: true);
  }

  Future<void> saveBedtime({required DateTime bedtime, required DateTime wakeUpTime}) async {
    try {
      setBusy(true);
      lucidManager.saveBedtime(bedtime.millisecondsSinceEpoch, wakeUpTime.millisecondsSinceEpoch);
      final numberOfReminders = lucidManager.realityCheck.getNumberOfReminders();
      await scheduleRealityCheckNotification(
        notificationType: NotificationType.realityCheckingBedtimeNotification,
        startTime: bedtime,
        endTime: wakeUpTime,
        numberOfReminders: numberOfReminders,
      );
    } catch (e) {
      _logger.log(Level.WARNING, e);
    } finally {
      setBusy(false);
    }
  }
}
