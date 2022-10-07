import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

const int _notificationMessageId = 999;

Future showAlertNotification(
    int id, String title, String body, {Map<String, String>? payload}) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: payload,
          wakeUpScreen: true
      )
  );
}

Future<void> _onBackgroundMessageReceived(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("message data: ${message.data}");

  final title = message.data["title"] ?? "";
  final body = message.data["body"] ?? "";

  Map<String, String> payload = {};
  for (String dataKey in message.data.keys) {
    if (message.data[dataKey] is String) {
      payload[dataKey] = message.data[dataKey];
    }
  }
  await showAlertNotification(_notificationMessageId, title, body, payload: payload);
}

// Navigation target type for a notification.
enum TargetType {
  protocol,
  survey
}

class NotificationController {

  static final CustomLogPrinter _logger = CustomLogPrinter('NotificationsManager');

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here

    _logger.log(Level.INFO, "User clicked on a notification.");
    _logger.log(Level.INFO, "User clicked on a notification going to "
        "${receivedAction.payload?[TargetType.protocol.name] ?? "dashboard."}");
    // Navigator.of(context).pushNamed(
    //     '/NotificationPage',
    //     arguments: {
    //       // your page params. I recommend you to pass the
    //       // entire *receivedNotification* object
    //       id: receivedNotification.id
    //     }
    // );
  }
}

class NotificationsManager {
  // TODO(alex): discuss notification types that can be replaced and fix
  // _notificationMessageId depends on notification entity type

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
              channelGroupKey: 'basic_channel_group',
              channelGroupName: 'Basic group')
        ],
        debug: true
    );
    // TODO(eric): Do in permission manager.
    // AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    //   if (!isAllowed) {
    //     // This is just a basic example. For real apps, you must show some
    //     // friendly dialog box before call the request method.
    //     // This is very important to not harm the user experience
    //     AwesomeNotifications().requestPermissionToSendNotifications();
    //   }
    // });

    // This provided handler must be a top-level function and cannot be anonymous otherwise an
    // [ArgumentError] will be thrown.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessageReceived);
    FirebaseMessaging.onMessage.listen((message) => _onForegroundMessageReceived(message));

    var messaging = FirebaseMessaging.instance;
    messaging.getToken().then((token)=> _onFcmTokenUpdated(token!));
    messaging.onTokenRefresh.listen(_onFcmTokenUpdated);

    _logger.log(Level.INFO, 'initialized');
  }

  Future hideAlertNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  _onForegroundMessageReceived(RemoteMessage message) {
    _logger.log(Level.INFO, 'foreground message received: '
        'title: "${message.notification?.title}" '
        'text: "${message.notification?.body}" '
        'from: ${message.from} - data: ${message.data}');

    final title = message.data["title"] ?? "";
    final body = message.data["body"] ?? "";

    Map<String, String> payload = {};
    for (String dataKey in message.data.keys) {
      if (message.data[dataKey] is String) {
        payload[dataKey] = message.data[dataKey];
      }
    }
    showAlertNotification(_notificationMessageId, title, body, payload: payload);
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
