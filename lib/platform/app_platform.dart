import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which operating system the app is running on, as far as behaviour goes.
enum PlatformKind { windows, android, ios, other }

/// What this platform can do, asked as capabilities rather than by testing the
/// operating system at every call site.
///
/// The app is one code base with two ways of working:
///  * on Windows it lives in the tray and shows each reminder in a floating
///    window it controls ([hasWindowShell]);
///  * on a phone it hands reminders to the OS as notifications and counts them
///    on an in-app screen ([usesNotifications]).
///
/// Everything that differs between the two asks this class, which is also the
/// one place tests change to exercise the other platform: override
/// [appPlatformProvider] with an `AppPlatform(PlatformKind.android)`.
@immutable
class AppPlatform {
  const AppPlatform(this.kind, {this.isRelease = kReleaseMode});

  /// The platform this process is running on.
  factory AppPlatform.current() {
    if (kIsWeb) return const AppPlatform(PlatformKind.other);
    if (Platform.isWindows) return const AppPlatform(PlatformKind.windows);
    if (Platform.isAndroid) return const AppPlatform(PlatformKind.android);
    if (Platform.isIOS) return const AppPlatform(PlatformKind.ios);
    return const AppPlatform(PlatformKind.other);
  }

  final PlatformKind kind;

  /// A release build. Anything that registers this copy of the app with the
  /// system (start with Windows) is only offered to the installed one.
  final bool isRelease;

  /// A tray icon and one native window that is re-shaped into the splash, the
  /// reminder popup, the tray menu and the settings screen.
  bool get hasWindowShell => kind == PlatformKind.windows;

  /// Reminders are scheduled with the OS as notifications, and counted on an
  /// in-app screen when one is opened.
  bool get usesNotifications =>
      kind == PlatformKind.android || kind == PlatformKind.ios;

  /// The app can download and run its own installer.
  bool get canSelfUpdate => kind == PlatformKind.windows;

  /// New versions arrive through an app store (Google Play), which does the
  /// downloading and installing. The app must not update itself there, and
  /// does not even ask the network: all it can do is point at the store page.
  bool get updatesThroughStore => kind == PlatformKind.android;

  /// The app can register itself to start when the person signs in.
  bool get canAutostart => hasWindowShell && isRelease;

  /// The in-process timer shows the reminders. Off where the OS delivers them
  /// instead, since both together would double every dhikr.
  bool get remindsInProcess => !usesNotifications;
}

/// The platform in use. Overridden in tests.
final appPlatformProvider = Provider<AppPlatform>(
  (ref) => AppPlatform.current(),
);
