import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';


Future<void> _onBackgroundMessageReceived(RemoteMessage message) async {

  print("Handling a background message: ${message.messageId}");

  // Creates a notification using the AwesomeNotifications FCM message parser.
  AwesomeNotifications().createNotificationFromJsonData(message.data);
}

// Navigation target type for a notification.
enum TargetType {
  protocol,
  survey
}

class NotificationsManager {
  // TODO(alex): discuss notification types that can be replaced and fix
  // _notificationMessageId depends on notification entity type
  static const int _notificationMessageId = 999;

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
              channelDescription: 'Important alerts on NextSense device and application',
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

    // This provided handler must be a top-level function and cannot be anonymous otherwise an
    // [ArgumentError] will be thrown.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessageReceived);

    FirebaseMessaging.onMessage.listen((message) => _onForegroundMessageReceived(message));

    var messaging = FirebaseMessaging.instance;
    messaging.getToken().then((token)=> _onFcmTokenUpdated(token!));
    messaging.onTokenRefresh.listen(_onFcmTokenUpdated);

    AwesomeNotifications().actionStream.listen((ReceivedNotification notification) {
      _logger.log(Level.INFO, "User clicked on a notification.");
      _logger.log(Level.INFO, "User clicked on a notification going to "
          "${notification.payload?[TargetType.protocol.name] ?? "dashboard."}");
      // Navigator.of(context).pushNamed(
      //     '/NotificationPage',
      //     arguments: {
      //       // your page params. I recommend you to pass the
      //       // entire *receivedNotification* object
      //       id: receivedNotification.id
      //     }
      // );
    });
    _logger.log(Level.INFO, 'initialized');
  }

  Future showAlertNotification(
      int id, String title, String body, {String? payload}) async {
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

  _onForegroundMessageReceived(RemoteMessage message) {
    _logger.log(Level.INFO, 'foreground message received: '
        'title: "${message.notification?.title}" '
        'text: "${message.notification?.body}" '
        'from: ${message.from} - data: ${message.data}');

    // Creates a notification using the AwesomeNotifications FCM message parser.
    AwesomeNotifications().createNotificationFromJsonData(message.data);

    final title = message.notification?.title ?? "";
    final body = message.notification?.body ?? "";

    showAlertNotification(_notificationMessageId, title, body);
  }

  void _onFcmTokenUpdated(String fcmToken) {
    getIt<Preferences>().setString(PreferenceKey.fcmToken, fcmToken);
    final _authManager = getIt<AuthManager>();
    if (_authManager.user != null) {
      _authManager.user!
        ..setFcmToken(fcmToken)
        ..save();
    }
  }
}
