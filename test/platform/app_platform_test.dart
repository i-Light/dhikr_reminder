import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows has the window shell and the in-process timer', () {
    const windows = AppPlatform(PlatformKind.windows);

    expect(windows.hasWindowShell, isTrue);
    expect(windows.usesNotifications, isFalse);
    expect(windows.remindsInProcess, isTrue);
    expect(windows.canSelfUpdate, isTrue);
  });

  test('Android hands reminders to the OS and has no window shell', () {
    const android = AppPlatform(PlatformKind.android);

    expect(android.hasWindowShell, isFalse);
    expect(android.usesNotifications, isTrue);
    expect(android.remindsInProcess, isFalse);
    expect(android.canSelfUpdate, isFalse);
    expect(android.canAutostart, isFalse);
  });

  test('autostart is only offered to the installed (release) Windows copy', () {
    expect(
      const AppPlatform(PlatformKind.windows, isRelease: true).canAutostart,
      isTrue,
    );
    expect(
      const AppPlatform(PlatformKind.windows, isRelease: false).canAutostart,
      isFalse,
    );
  });

  test('an unknown platform can do none of it', () {
    const other = AppPlatform(PlatformKind.other);

    expect(other.hasWindowShell, isFalse);
    expect(other.usesNotifications, isFalse);
    expect(other.canSelfUpdate, isFalse);
  });
}
