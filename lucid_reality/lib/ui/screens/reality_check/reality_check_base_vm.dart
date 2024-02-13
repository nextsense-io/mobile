import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/lucid_manager.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/utils/notification.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:progressive_time_picker/progressive_time_picker.dart';

class RealityCheckBaseViewModel extends ViewModel {
  final CustomLogPrinter _logger = CustomLogPrinter('RealityCheckBaseViewModel');
  final Navigation navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final LucidManager lucidManager = getIt<LucidManager>();

  @override
  void init() async {
    super.init();
    setBusy(true);
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      await lucidManager.fetchIntent();
      await lucidManager.fetchRealityCheck();
    }
    setBusy(false);
  }

  void goBack() {
    navigation.pop();
  }

  void goBackWithResult<T extends Object?>([T? result]) {
    navigation.popWithResult(result);
  }

  Future<void> scheduleRealityCheckNotification(
      {required NotificationType notificationType,
      required DateTime startTime,
      required DateTime endTime,
      required int numberOfReminders}) async {
    final realityTest = lucidManager.realityCheck.getRealityTest();
    if (realityTest != null) {
      final sound =
          '${realityTest.getTotemSound()}'.replaceAll(" ", '_').plus('.${realityTest.getType()}');
      final totalTime = formatIntervalTime(
          init: PickedTime(h: startTime.hour, m: startTime.minute),
          end: PickedTime(h: endTime.hour, m: endTime.hour));
      // Calculate interval offset
      final timeOffset = Duration(
          seconds:
              Duration(hours: totalTime.h, minutes: totalTime.m).inSeconds ~/ numberOfReminders);
      var initialTime = startTime;
      for (int i = 0; i < numberOfReminders; i++) {
        // Schedule each notification with calculated interval
        _logger.log(Level.INFO, "Time:${initialTime.hour}:${initialTime.minute}, Sound:$sound");
        await scheduleNotification(
          notificationType: notificationType,
          date: initialTime,
          title: realityTest.getName() ?? '',
          message: realityTest.getDescription() ?? '',
          sound: sound,
        );
        initialTime = initialTime.add(timeOffset);
      }
    }
  }
}
