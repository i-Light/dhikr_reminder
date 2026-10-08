# Vendored: flutter_local_notifications_windows 3.1.1

A copy of the upstream package with its `windows/` and `src/` native code
removed, wired in through `dependency_overrides` in the app's pubspec.yaml.

Why: `flutter_local_notifications` pulls this package in for Windows, whose
native part needs the Visual C++ ATL libraries. Dhikr Reminder shows its
reminders in its own popup window on Windows and only uses notifications on
Android, so the native Windows build would be extra toolchain for code that is
never called. The Dart side is unchanged and is never invoked on Windows.

Delete this folder and the override when upstream stops requiring ATL, or if
the app ever wants system toasts on Windows.

One Dart change: `_library` in `lib/src/plugin/ffi.dart` is `late final`, so
the missing DLL is only looked up if the Windows notifications are really used.
Before, `registerWith()` opened it at startup and logged a load error (126).
