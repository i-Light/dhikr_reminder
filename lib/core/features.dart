/// One switch per optional feature, so anything that is not liked can be turned
/// off by changing one `true` to `false`. With a flag off, the feature's entry
/// point does not show, nothing of it runs, and nothing else depends on it.
///
/// Rules for adding a flag (docs/roadmap.md, "Product principles"):
///  * the flag gates the entry point (a button, a row, a listener), not the
///    inside of the feature;
///  * a feature that is off must cost nothing at startup;
///  * tests for a feature skip themselves on its flag (`skip: !Features.x`).
///
/// Fixes and safety work (atomic saves, the Android notification fallback) are
/// not features and have no flag.
abstract final class Features {
  /// The counter screen, reachable from a dhikr in the reminders list.
  static const counter = true;

  /// A history of daily totals, with an optional private streak line.
  static const history = true;

  /// Optional soft sounds on completion (off until the person turns it on).
  static const sound = true;

  /// Morning and evening sessions that run a set of dhikr in order.
  static const sessions = true;

  /// Favourites and "my wird" (a named ordered list of library dhikr).
  static const wird = true;

  /// Export and import of the saved data as one file.
  static const backup = true;

  /// Quiet hours, snooze and the other polite-reminder options.
  static const politeReminders = true;

  /// The "Report a mistake" button on a library entry.
  static const reportMistake = true;

  /// Android: counting from outside the app (home-screen widget, quick-settings
  /// tiles, launcher shortcuts, "Done" and "Later" on a reminder notification).
  /// Also the words and the pause hand-over that go with them. The native half
  /// has its own switch, `Features.SURFACES` in Features.kt; flip both.
  static const surfaces = true;

  /// Press and hold a library entry to copy (Windows) or share (Android) its
  /// text. Off, the press goes straight to "Report a mistake".
  static const shareText = true;

  /// Windows: a "Count one" row in the tray menu and today's total in the tray
  /// tooltip.
  static const trayCount = true;
}
