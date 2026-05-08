import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import '../models/bill_model.dart';

class NotificationService {
  static const channelId = 'bill_reminder';
  static const channelName = 'Bill Reminders';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
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

    // Request permissions (iOS 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> scheduleNotification(BillModel bill) async {
    try {
      final DateTime notificationTime = _calculateNotificationTime(bill);

      // If notification time is in the past, don't schedule
      if (notificationTime.isBefore(DateTime.now())) {
        print('⚠️ Notification time is in the past, skipping scheduling');
        return;
      }

      print('⏰ Scheduling notification for: $notificationTime');
      print('Bill: ${bill.billType} - Due: ${bill.dueDate}');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for bill reminders',
        importance: Importance.high,
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

      final String title = '🔔 ${bill.billType} Bill Reminder!';
      final String body = 'PKR ${bill.amount.toStringAsFixed(0)} due on '
          '${_formatDate(bill.dueDate)}. Time to pay!';

      await _notificationsPlugin.zonedSchedule(
        bill.id.hashCode,
        title,
        body,
        tz.TZDateTime.from(notificationTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );

      print('✅ Notification scheduled successfully!');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  static DateTime _calculateNotificationTime(BillModel bill) {
    DateTime dueDate = bill.dueDate;

    if (bill.reminderDaysBefore == 0) {
      // 30 minutes before due date
      return dueDate.subtract(const Duration(minutes: 30));
    } else {
      // For 1, 3, 7 days - schedule at 9:00 AM
      DateTime reminderDate =
          dueDate.subtract(Duration(days: bill.reminderDaysBefore));
      return DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9, // 9 AM
        0,
      );
    }
  }

  static Future<void> cancelNotification(String billId) async {
    try {
      await _notificationsPlugin.cancel(billId.hashCode);
      print('✅ Notification cancelled for bill: $billId');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  static String _formatDate(DateTime date) {
    final format = DateFormat('d MMMM, yyyy');
    return format.format(date);
  }
}
