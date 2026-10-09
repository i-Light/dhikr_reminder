import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the phone says about whether reminders are getting through (see
/// `MainActivity.health` on the Android side).
@immutable
class ReminderHealth {
  const ReminderHealth({
    this.stopped = false,
    this.notificationsEnabled = true,
    this.channelBlocked = false,
    this.canDrawOverlays = true,
    this.ignoringBattery = true,
    this.armed = 0,
    this.manufacturer = '',
    this.sdk = 0,
    this.events = const [],
  });

  /// No reminder has arrived for more than two intervals although some are armed.
  final bool stopped;
  final bool notificationsEnabled;

  /// The reminders' notification channel was switched off by the person.
  final bool channelBlocked;
  final bool canDrawOverlays;
  final bool ignoringBattery;
  final int armed;
  final String manufacturer;
  final int sdk;

  /// The last few things that happened to reminders, `millis|kind|detail`.
  final List<String> events;

  /// Notifications cannot reach the person at all.
  bool get notificationsBlocked => !notificationsEnabled || channelBlocked;

  factory ReminderHealth.fromMap(Map<Object?, Object?> map) {
    bool flag(String key, bool fallback) => map[key] is bool ? map[key]! as bool : fallback;
    int number(String key) => map[key] is num ? (map[key]! as num).toInt() : 0;
    return ReminderHealth(
      stopped: flag('stopped', false),
      notificationsEnabled: flag('notificationsEnabled', true),
      channelBlocked: flag('channelBlocked', false),
      canDrawOverlays: flag('canDrawOverlays', true),
      ignoringBattery: flag('ignoringBattery', true),
      armed: number('armed'),
      manufacturer: '${map['manufacturer'] ?? ''}',
      sdk: number('sdk'),
      events: [
        if (map['events'] is List)
          for (final e in map['events']! as List) '$e',
      ],
    );
  }

  /// A few plain lines for a bug report: no dhikr text, no personal data.
  String describe() {
    final lines = <String>[
      'Reminders armed: $armed${stopped ? ' (STOPPED)' : ''}',
      'Notifications on: $notificationsEnabled, channel blocked: $channelBlocked',
      'Over other apps: $canDrawOverlays, battery exempt: $ignoringBattery',
      if (events.isNotEmpty) 'Recent reminder events (time|what|why):',
      ...events,
    ];
    return lines.join('\n');
  }
}

/// The health, asked of the phone. Refreshed when the app comes to the
/// foreground. Null where there is nothing to ask (Windows, tests).
class ReminderHealthNotifier extends AsyncNotifier<ReminderHealth?> {
  @override
  Future<ReminderHealth?> build() async {
    if (!ref.read(appPlatformProvider).usesNotifications) return null;
    return ref.read(reminderOverlayProvider).health();
  }

  Future<void> refresh() async {
    if (!ref.read(appPlatformProvider).usesNotifications) return;
    state = AsyncData(await ref.read(reminderOverlayProvider).health());
  }
}

final reminderHealthProvider =
    AsyncNotifierProvider<ReminderHealthNotifier, ReminderHealth?>(
  ReminderHealthNotifier.new,
);
