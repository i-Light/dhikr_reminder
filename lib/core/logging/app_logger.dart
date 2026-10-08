import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Where uncaught errors go, so a bug report from a machine without a debugger
/// has something to attach. One file, rotated once it passes [_maxBytes] (the
/// previous one is kept as `.old`), in the user's local app data.
class AppLogger {
  AppLogger._();

  static const _maxBytes = 512 * 1024;
  static File? _file;

  /// The log file, once [install] has found a place for it.
  static File? get file => _file;

  /// Routes Flutter framework errors, uncaught async errors and platform
  /// errors into the log (and still prints them in debug).
  static void install() {
    _file = _locate();

    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      write('FlutterError', details.exception, details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      write('Uncaught', error, stack);
      return true;
    };
  }

  /// Runs [body] so errors thrown out of it are logged too.
  static void guard(void Function() body) {
    runZonedGuarded(body, (error, stack) => write('Zone', error, stack));
  }

  /// Writes a line that is not an error but is worth having in a bug report,
  /// such as what the updater did.
  static void note(String message) => write('Info', message, null);

  static void write(String kind, Object error, StackTrace? stack) {
    if (kDebugMode) debugPrint('[$kind] $error${stack == null ? '' : '\n$stack'}');
    final file = _file;
    if (file == null) return;
    try {
      if (file.existsSync() && file.lengthSync() > _maxBytes) {
        final old = File('${file.path}.old');
        if (old.existsSync()) old.deleteSync();
        file.renameSync(old.path);
      }
      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()} [$kind] $error\n'
        '${stack == null ? '' : '$stack\n'}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Logging must never be the thing that crashes the app.
    }
  }

  static File? _locate() {
    if (kIsWeb) return null;
    try {
      // On a phone the app cache folder (the temp directory) is the one place
      // the app may write without a plugin.
      final base = Platform.isAndroid
          ? Directory.systemTemp.path
          : Platform.environment['LOCALAPPDATA'] ??
              Platform.environment['HOME'] ??
              Directory.systemTemp.path;
      final dir = Directory('$base${Platform.pathSeparator}DhikrReminder')
        ..createSync(recursive: true);
      return File('${dir.path}${Platform.pathSeparator}dhikr_reminder.log');
    } catch (_) {
      return null;
    }
  }
}
