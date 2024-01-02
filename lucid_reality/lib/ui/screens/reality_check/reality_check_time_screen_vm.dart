import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/utils/notification.dart';

import 'reality_check_tone_category_screen.dart';

class RealityCheckTimeScreenViewModel extends RealityCheckBaseViewModel {
  void navigateToToneCategoryScreen() async {
    navigation.navigateTo(RealityCheckToneCategoryScreen.id, replace: true);
  }

  Future<void> saveNumberOfReminders(
      {required DateTime startTime,
      required DateTime endTime,
      required int numberOfReminders}) async {
    try {
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
    } catch (e) {
      print(e);
    }
  }
}
