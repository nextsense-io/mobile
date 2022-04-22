import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  print("Handling a background message: ${message.messageId}");

  // Use this method to automatically convert the push data,
  // in case you gonna use our data standard
  AwesomeNotifications().createNotificationFromJsonData(message.data);
}

class NotificationsManager {

  final CustomLogPrinter _logger = CustomLogPrinter('NotificationsManager');
  
  NotificationManager() {}

  Future init() async {
    _logger.log(Level.INFO, 'initializing');
    AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
        null,
        [
          NotificationChannel(
              channelGroupKey: 'basic_channel_group',
              channelKey: 'basic_channel',
              channelName: 'NextSense Alerts',
              channelDescription:
                  'Important alerts on NextSense device and application',
              importance: NotificationImportance.Max,
              enableVibration: true,
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white)
        ],
        // Channel groups are only visual and are not required
        channelGroups: [
          NotificationChannelGroup(
              channelGroupkey: 'basic_channel_group',
              channelGroupName: 'Basic group')
        ],
        debug: true
    );
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // This is just a basic example. For real apps, you must show some
        // friendly dialog box before call the request method.
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    var messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value){
      _onFcmTokenUpdated(value!);
    });

    _logger.log(Level.INFO, 'initialized');
  }

  Future showAlertNotification(
      int id, String title, String body, String payload) async {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: title,
            body: body,
            wakeUpScreen: true
        )
    );
  }

  Future hideAlertNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  void _onFcmTokenUpdated(String fcmToken) {
    getIt<Preferences>().setString(PreferenceKey.fcmToken, fcmToken);
    final _authManager = getIt<AuthManager>();
    if (_authManager.user!=null) {
      _authManager.user!
        ..setFcmToken(fcmToken)
        ..save();
    }
  }

}
