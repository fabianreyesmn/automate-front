import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.local);
    debugPrint('NotificationService initialized. Local timezone set to: ${tz.local.name}');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
        // For example, navigate to the reminder details screen
        debugPrint('Notification tapped: ${notificationResponse.payload}');
      },
    );
  }

  Future<bool?> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // For Android 13 (API 33) and above, explicit permission is required
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        return granted;
      }
    }
    return true; // Assume granted for other platforms or if implementation is null
  }

  Future<void> scheduleNotification(
      Reminder reminder, int daysBefore, int notificationId) async {
    final notificationDate =
        reminder.dueDate.subtract(Duration(days: daysBefore));

    // Ensure the notification is scheduled for a future time
    if (notificationDate.isBefore(DateTime.now())) {
      debugPrint('Notification date is in the past for reminder: ${reminder.title}');
      return;
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Recordatorio: ${reminder.title}',
      'Vence en $daysBefore días. ${reminder.notes ?? ''}',
      tz.TZDateTime.from(notificationDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Notifications',
          channelDescription: 'Notifications for upcoming reminders',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: reminder.id, // Pass reminder ID as payload
    );
    debugPrint('Scheduled notification for ${reminder.title} on $notificationDate');
  }

  Future<void> cancelNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    debugPrint('Cancelled notification with ID: $notificationId');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Cancelled all notifications');
  }
}
