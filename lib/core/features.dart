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

  /// Morning, evening and "my wird" sessions: a screen with one Start button
  /// each (one tap deeper than the folded reminder settings on the
  /// Notifications page) that runs the dhikr in order on the reminder card with
  /// "3 of 31" on it. Started by the person; there are no timed sessions.
  static const sessions = true;

  /// Favourites and "my wird": press and hold a library entry to star it; the
  /// stars (in the order they were made) are the wird. Adds a small star on a
  /// starred card, a Favourites chip in the library filter, favourites first
  /// while choosing what to add, and the wird row in the sessions screen.
  static const wird = true;

  /// Export and import of the saved data as one file ("Backup" at the bottom of
  /// the About page).
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

  /// Windows: a row in the tray menu that names the dhikr last shown, adds one
  /// to it and says how many of it today, and today's total in the tray tooltip.
  static const trayCount = true;
}
