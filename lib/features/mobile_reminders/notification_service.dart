import 'dart:async';

import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// What the app needs from the phone's notification system. An interface so
/// the logic around it can be tested without a device.
abstract class ReminderNotifications {
  /// Prepares the plugin. [onOpen] gets the dhikr id of a notification the
  /// person tapped — including the one that launched the app, if any.
  Future<void> init({required void Function(int entryId) onOpen});

  /// Asks for the notification permission (Android 13+). True if granted.
  Future<bool> requestPermission();

  /// Cancels everything scheduled and schedules [plan] instead.
  Future<void> replaceAll(
    List<PlannedReminder> plan, {
    required String title,
  });
}

const _channelId = 'dhikr_reminders';

/// [ReminderNotifications] on top of flutter_local_notifications (Android).
///
/// Notifications are scheduled with `inexactAllowWhileIdle`: a dhikr does not
/// need to land on the exact second, and this avoids the exact-alarm
/// permission that Google Play restricts. Android may move one by a few
/// minutes when the phone is dozing.
class LocalReminderNotifications implements ReminderNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init({required void Function(int entryId) onOpen}) async {
    tzdata.initializeTimeZones();
    void open(String? payload) {
      final id = int.tryParse(payload ?? '');
      if (id != null) onOpen(id);
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) => open(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      open(launch?.notificationResponse?.payload);
    }
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> replaceAll(
    List<PlannedReminder> plan, {
    required String title,
  }) async {
    await _plugin.cancelAllPendingNotifications();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Dhikr reminders',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
    );
    for (final reminder in plan) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: title,
          body: reminder.entry.name,
          // An absolute instant: UTC avoids needing the device's zone name.
          scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: '${reminder.entry.id}',
        );
      } catch (error, stack) {
        debugPrint(
            'Could not schedule reminder ${reminder.id}: $error\n$stack');
      }
    }
  }
}
