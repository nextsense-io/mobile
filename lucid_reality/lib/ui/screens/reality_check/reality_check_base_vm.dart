import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/reality_test.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/lucid_manager.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/utils/notification.dart';
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

  Future<void> saveRealityTest(RealityTest realityTest) async {
    await lucidManager.saveRealityTest(realityTest);
  }

  Future<void> scheduleNewToneNotifications(String sound) async {
    try {
      await clearNotifications();
      // Create a notification channel with the current sound if it did not exist.
      final formattedSound = sound.replaceAll(" ", '_').toLowerCase();
      await updateNotificationsSound(sound: formattedSound);
      _logger.log(Level.INFO, "Scheduling new notifications with $formattedSound sound.");
      // Scheduling Daytime notification
      final numberOfReminders = lucidManager.realityCheck.getNumberOfReminders();
      final int? startTime = lucidManager.realityCheck.getStartTime();
      final int? endTime = lucidManager.realityCheck.getEndTime();
      await scheduleRealityCheckNotification(
        notificationType: NotificationType.realityCheckingTimeNotification,
        startTime: DateTime.fromMillisecondsSinceEpoch(startTime!),
        endTime: DateTime.fromMillisecondsSinceEpoch(endTime!),
        numberOfReminders: numberOfReminders,
      );
      // Scheduling Bedtime notification
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
    } catch (e) {
      _logger.log(Level.WARNING, e);
    }
  }

  Future<void> scheduleRealityCheckNotification(
      {required NotificationType notificationType,
      required DateTime startTime,
      required DateTime endTime,
      required int numberOfReminders}) async {
    final realityTest = lucidManager.realityCheck.getRealityTest();
    if (realityTest != null) {
      final String sound = realityTest.getTotemSound()?.replaceAll(" ", '_').toLowerCase() ?? 'air';
      final totalTime = formatIntervalTime(
          init: PickedTime(h: startTime.hour, m: startTime.minute),
          end: PickedTime(h: endTime.hour, m: endTime.hour));
      // Calculate interval offset
      final timeOffset = Duration(
          seconds:
              Duration(hours: totalTime.h, minutes: totalTime.m).inSeconds ~/ numberOfReminders);
      var initialTime = startTime;
      //Before scheduling new notifications we have to cancelled all previous scheduled notifications.
      await AwesomeNotifications()
          .cancelSchedulesByChannelKey(notificationType.notificationChannelKey);
      for (int i = 0; i < numberOfReminders; i++) {
        // Schedule each notification with calculated interval
        _logger.log(Level.INFO, "Time:${initialTime.hour}:${initialTime.minute}, Sound:$sound");
        await scheduleNotifications(
          notificationId: numberOfReminders + 1,
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
