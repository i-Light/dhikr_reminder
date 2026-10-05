import 'dart:io';

import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _firstRunDonePrefsKey = 'dhikr_reminder.autostart.firstRunDone';

/// Starting with the operating system: the platform's side of the "Start with
/// Windows" switch.
abstract class AutostartService {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
}

const _runKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
const _valueName = 'DhikrReminder';

/// Windows: a value in the per-user `Run` registry key. The registry is the
/// source of truth, so the switch always shows what Windows will really do,
/// and the installer's uninstaller removes the same value.
class WindowsAutostartService implements AutostartService {
  @override
  Future<bool> isEnabled() async {
    final result =
        await Process.run('reg', ['query', _runKey, '/v', _valueName]);
    return result.exitCode == 0;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final result = enabled
        ? await Process.run('reg', [
            'add', _runKey, '/v', _valueName, '/t', 'REG_SZ', '/f', '/d',
            // Quoted: the install path has spaces.
            '"${Platform.resolvedExecutable}"',
          ])
        : await Process.run('reg', ['delete', _runKey, '/v', _valueName, '/f']);
    if (result.exitCode != 0 && enabled) {
      throw ProcessException('reg', const ['add'], '${result.stderr}');
    }
  }
}

/// Everywhere else: nothing to register.
class NoAutostartService implements AutostartService {
  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(bool enabled) async {}
}

/// The platform's autostart. Overridden in tests with a fake.
final autostartServiceProvider = Provider<AutostartService>((ref) {
  return ref.watch(appPlatformProvider).canAutostart
      ? WindowsAutostartService()
      : NoAutostartService();
});

/// Whether the app starts with the system. Only meaningful where
/// `AppPlatform.canAutostart` is true; elsewhere it is simply false.
///
/// On by default: the first time the switch is available it turns itself on,
/// once. Switching it off afterwards is respected, because the first run is
/// remembered separately from the setting.
class AutostartNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final service = ref.read(autostartServiceProvider);
    if (ref.read(appPlatformProvider).canAutostart) {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_firstRunDonePrefsKey) ?? false)) {
        await prefs.setBool(_firstRunDonePrefsKey, true);
        try {
          await service.setEnabled(true);
        } on ProcessException {
          // Left off; the switch shows what Windows really has.
        }
      }
    }
    return service.isEnabled();
  }

  Future<void> set(bool enabled) async {
    await ref.read(autostartServiceProvider).setEnabled(enabled);
    state = AsyncData(enabled);
  }
}

final autostartProvider =
    AsyncNotifierProvider<AutostartNotifier, bool>(AutostartNotifier.new);
