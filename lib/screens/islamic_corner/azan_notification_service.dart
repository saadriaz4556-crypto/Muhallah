import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class AzanNotificationService {
  static const String channelId = 'azan_reminders';
  static const String channelName = 'Azan Reminders';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await _notificationsPlugin.initialize(settings);
  }

  // Check if a prayer is enabled
  static Future<bool> isPrayerEnabled(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('azan_enabled_$prayerName') ?? false;
  }

  // Set prayer notification enabled/disabled status
  static Future<void> setPrayerEnabled(String prayerName, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('azan_enabled_$prayerName', enabled);
  }

  // Schedule notification for a specific prayer
  static Future<void> schedulePrayerReminder({
    required int id,
    required String prayerName,
    required String prayerUrdu,
    required DateTime prayerTime,
  }) async {
    try {
      // Cancel any existing notification for this prayer ID first
      await _notificationsPlugin.cancel(id);

      final isEnabled = await isPrayerEnabled(prayerName);
      if (!isEnabled) {
        print('Azan notification for $prayerName is disabled, not scheduling.');
        return;
      }

      // If the time has already passed today, schedule for tomorrow
      DateTime scheduleTime = prayerTime;
      if (scheduleTime.isBefore(DateTime.now())) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }

      print('Scheduling Azan Notification for $prayerName at $scheduleTime');

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for Azan times',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        '🕌 Namaz Time: $prayerName / $prayerUrdu',
        'It is time for $prayerName prayer. Click to open Digital Mohallah.',
        tz.TZDateTime.from(scheduleTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );

      print('✅ Scheduled $prayerName successfully!');
    } catch (e) {
      print('❌ Error scheduling Azan for $prayerName: $e');
    }
  }

  // Cancel notification for a prayer
  static Future<void> cancelPrayerReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      print('✅ Notification cancelled for ID: $id');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }
}
