import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/utils/notification.dart';

import 'reality_check_tone_category_screen.dart';

class RealityCheckTimeScreenViewModel extends RealityCheckBaseViewModel {
  final CustomLogPrinter _logger = CustomLogPrinter('RealityCheckBedtimeScreenViewModel');

  void navigateToToneCategoryScreen() async {
    navigation.navigateTo(RealityCheckToneCategoryScreen.id, replace: true);
  }

  Future<void> saveNumberOfReminders({
    required DateTime startTime,
    required DateTime endTime,
    required int numberOfReminders,
    bool reminderCountChanged = false,
  }) async {
    try {
      setBusy(true);
      await lucidManager.saveNumberOfReminders(
          startTime: startTime.millisecondsSinceEpoch,
          endTime: endTime.millisecondsSinceEpoch,
          numberOfReminders: numberOfReminders);
      await scheduleRealityCheckNotification(
        notificationType: NotificationType.realityCheckingTimeNotification,
        startTime: startTime,
        endTime: endTime,
        numberOfReminders: numberOfReminders,
      );
      if (reminderCountChanged) {
        final DateTime bedtime =
            DateTime.fromMillisecondsSinceEpoch(lucidManager.realityCheck.getEndTime() ?? 0);
        final DateTime wakeUpTime =
            DateTime.fromMillisecondsSinceEpoch(lucidManager.realityCheck.getWakeTime() ?? 0);
        await scheduleRealityCheckNotification(
          notificationType: NotificationType.realityCheckingBedtimeNotification,
          startTime: bedtime,
          endTime: wakeUpTime,
          numberOfReminders: numberOfReminders,
        );
      }
    } catch (e) {
      _logger.log(Level.WARNING, e);
    } finally {
      setBusy(false);
    }
  }
}
