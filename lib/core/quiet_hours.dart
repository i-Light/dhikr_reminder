import 'package:flutter/foundation.dart';

/// A daily window in which no reminder is shown (for example while asleep).
///
/// Both ends are minutes after midnight on the device's clock. The window may
/// cross midnight (23:00 to 06:00); start equal to end means "never quiet", not
/// "always quiet", so a half-edited setting can never silence everything.
@immutable
class QuietHours {
  const QuietHours({
    this.enabled = false,
    this.startMinutes = defaultStart,
    this.endMinutes = defaultEnd,
  });

  static const defaultStart = 23 * 60;
  static const defaultEnd = 6 * 60;

  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  /// Whether [time] falls inside the window.
  bool contains(DateTime time) {
    if (!enabled || startMinutes == endMinutes) return false;
    final minute = time.hour * 60 + time.minute;
    return startMinutes < endMinutes
        ? minute >= startMinutes && minute < endMinutes
        : minute >= startMinutes || minute < endMinutes;
  }

  QuietHours copyWith({bool? enabled, int? startMinutes, int? endMinutes}) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );

  @override
  bool operator ==(Object other) =>
      other is QuietHours &&
      other.enabled == enabled &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(enabled, startMinutes, endMinutes);
}
