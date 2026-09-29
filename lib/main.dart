import 'dart:async';

import 'package:dhikr_reminder/app.dart';
import 'package:dhikr_reminder/core/update/update_controller.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The container is built up front, rather than left to a `ProviderScope`,
  // because the tray has to be up (and the close button taken over) before the
  // first frame — otherwise a window closed in that gap would just quit.
  final container = ProviderContainer();
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
}
