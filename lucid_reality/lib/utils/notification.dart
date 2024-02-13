// Function to schedule a notification at a specific time
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

const String _realityCheckingTimeChannelKey = 'realityCheckingTimeChannel';
const String _realityCheckingBedTimeChannelKey = 'realityCheckingBedTimeChannel';
const int realityCheckingTimeNotificationId = 100;
const int realityCheckingBedtimeNotificationId = 200;

enum NotificationType {
  realityCheckingTimeNotification,
  realityCheckingBedtimeNotification,
}

extension NotificationTypeExtension on NotificationType {
  String get notificationChannelKey {
    switch (this) {
      case NotificationType.realityCheckingTimeNotification:
        return _realityCheckingTimeChannelKey;
      case NotificationType.realityCheckingBedtimeNotification:
        return _realityCheckingBedTimeChannelKey;
    }
  }
}

Future<bool> isDoNotDisturbOverriddenForChannel(
    {required NotificationType notificationType, required String sound}) async {
  List<NotificationPermission> permissionsAllowed = await AwesomeNotifications()
      .checkPermissionList(
      channelKey: '${notificationType.notificationChannelKey}$sound',
      permissions: [NotificationPermission.CriticalAlert]
  );
  if (permissionsAllowed.isNotEmpty) {
    return permissionsAllowed.first == NotificationPermission.CriticalAlert;
  }
  return false;
}

Future requestDoNotDisturbOverride(
    {required NotificationType notificationType, required String sound}) async {
  await AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: '${notificationType.notificationChannelKey}$sound',
      permissions: [NotificationPermission.CriticalAlert]
  );
}

Future<void> scheduleNotifications({
  required int notificationId,
  required NotificationType notificationType,
  required String title,
  required String message,
  required DateTime date,
  required String sound,
}) async {
    await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notificationId,
      channelKey: '${notificationType.notificationChannelKey}$sound',
      title: title,
      body: message,
      criticalAlert: true,
      wakeUpScreen: true,
      customSound: 'resource://raw/$sound',
    ),
    schedule: NotificationCalendar(
      hour: date.hour,
      minute: date.minute,
      second: date.second,
      repeats: true,
      preciseAlarm: true,
      allowWhileIdle: true,
    ),
  );
}

Future<void> clearNotifications() async {
  await AwesomeNotifications().cancelAll();
}

NotificationChannel getDaytimeNotificationChannel(String sound) {
  return NotificationChannel(
      channelKey: '$_realityCheckingTimeChannelKey$sound',
      channelName: 'Lucid Daytime Notifications $sound',
      channelDescription: 'Lucid reality time check notifications with $sound sound.',
      defaultColor: NextSenseColors.royalPurple,
      ledColor: NextSenseColors.royalPurple,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      playSound: true,
      // This is the only path that is accepted by AwesomeNotifications.
      soundSource: 'resource://raw/$sound'
  );
}

NotificationChannel getBedtimeNotificationChannel(String sound) {
  return NotificationChannel(
      channelKey: '$_realityCheckingBedTimeChannelKey$sound',
      channelName: 'Lucid Night Notifications $sound',
      channelDescription: 'Lucid reality bedtime check notifications with $sound sound.',
      defaultColor: NextSenseColors.royalPurple,
      ledColor: NextSenseColors.royalPurple,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      playSound: true,
      // This is the only path that is accepted by AwesomeNotifications.
      soundSource: 'resource://raw/$sound'
  );
}

Future<void> updateNotificationsSound({required String sound}) async {
  await AwesomeNotifications().setChannel(getDaytimeNotificationChannel(sound));
  await AwesomeNotifications().setChannel(getBedtimeNotificationChannel(sound));
}

Future<void> initializeNotifications() async {
  // Create the notification channels with air sound as a default one.
  AwesomeNotifications().initialize(
    'resource://drawable/ic_stat_onesignal_default',
    [
      getDaytimeNotificationChannel('air'),
      getBedtimeNotificationChannel('air'),
    ],
    debug: true,
  );
}

Future<bool> notificationPermission(BuildContext context) async {
  return AwesomeNotifications().isNotificationAllowed().then(
    (isAllowed) async {
      if (!isAllowed) {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Allow Notifications'),
            content: Text('Our app would like to send you notifications'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, isAllowed);
                },
                child: Text(
                  'Don\'t Allow',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () => AwesomeNotifications()
                    .requestPermissionToSendNotifications()
                    .then((isAllowed) => Navigator.pop(context, isAllowed)),
                child: Text(
                  'Allow',
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return Future(() => isAllowed);
      }
    },
  );
}
