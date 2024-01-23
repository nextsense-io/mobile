// Function to schedule a notification at a specific time
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/utils.dart';

const String realityCheckingTimeChannelKey = 'realityCheckingTimeChannel';
const String realityCheckingBedTimeChannelKey = 'realityCheckingBedTimeChannel';

enum NotificationType {
  realityCheckingTimeNotification,
  realityCheckingBedtimeNotification,
}

extension NotificationTypeExtension on NotificationType {
  String get notificationChannelKey {
    switch (this) {
      case NotificationType.realityCheckingTimeNotification:
        return realityCheckingTimeChannelKey;
      case NotificationType.realityCheckingBedtimeNotification:
        return realityCheckingBedTimeChannelKey;
    }
  }
}

Future<void> scheduleNotification({
  required NotificationType notificationType,
  required String title,
  required String message,
  required DateTime date,
  required String sound,
}) async {
  final notificationId = Random().nextInt(100); // Generate a unique ID
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notificationId,
      channelKey: notificationType.notificationChannelKey,
      title: title,
      body: message,
      criticalAlert: true,
      wakeUpScreen: true,
      customSound: customSoundPath.plus(sound),
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

Future<void> initializeNotification() async {
  AwesomeNotifications().initialize(
    'resource://drawable/android12splash',
    [
      NotificationChannel(
        channelKey: realityCheckingTimeChannelKey,
        channelName: 'Lucid Daytime Notifications',
        channelDescription: 'Lucid reality time check notifications.',
        defaultColor: NextSenseColors.royalPurple,
        ledColor: NextSenseColors.royalPurple,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelKey: realityCheckingBedTimeChannelKey,
        channelName: 'Lucid Night Notifications',
        channelDescription: 'Lucid reality bedtime check notifications.',
        defaultColor: NextSenseColors.royalPurple,
        ledColor: NextSenseColors.royalPurple,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
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
