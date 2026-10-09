import 'dart:async';

import 'package:dhikr_reminder/app.dart';
import 'package:dhikr_reminder/core/logging/app_logger.dart';
import 'package:dhikr_reminder/core/storage/backup_service.dart';
import 'package:dhikr_reminder/core/update/update_controller.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/data/requests_config.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:dhikr_reminder/platform/autostart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => AppLogger.guard(_start);

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.install();
  // Before anything reads the saved settings: refuses to overwrite settings
  // from a newer build, and on Windows puts them back from a backup if the file
  // was lost.
  final platform = AppPlatform.current();
  final restored = await prepareStorage(keepBackups: platform.hasWindowShell);
  // The container is built up front, rather than left to a `ProviderScope`,
  // because the tray has to be up (and the close button taken over) before the
  // first frame — otherwise a window closed in that gap would just quit.
  final container = ProviderContainer(
    overrides: [
      requestsUrlProvider.overrideWithValue(requestsApiUrl),
      restoredFromBackupProvider.overrideWithValue(restored),
    ],
  );
  await container.read(appShellProvider.notifier).init();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DhikrReminderApp(),
    ),
  );
  // The window starts hidden; this is what brings it up, as the splash.
  unawaited(container.read(appShellProvider.notifier).start());
  // Keeps the installed copy current; installs nothing for `flutter run`.
  container.read(updateProvider.notifier).start();
  if (platform.hasWindowShell) startPrefsBackup(container);
  // The first-run "start with Windows" registration happens when the switch's
  // state is first read, which used to be when Settings was first opened. A
  // person who never opens Settings would never get it, so read it here (only
  // where the switch exists at all).
  if (container.read(appPlatformProvider).canAutostart) {
    unawaited(container.read(autostartProvider.future));
  }
}
