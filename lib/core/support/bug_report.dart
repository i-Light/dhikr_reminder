import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dhikr_reminder/core/logging/app_logger.dart';
import 'package:dhikr_reminder/core/update/update_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// What a bug report says about the app and the device it ran on.
@immutable
class BugReportDetails {
  const BugReportDetails({
    required this.appVersion,
    required this.device,
    this.logTail,
  });

  /// `0.1.2 (3)`.
  final String appVersion;

  /// `Samsung SM-A546B, Android 14 (API 34)` or `Windows 11 Pro, build 26200`.
  final String device;

  /// The end of the app's log, when it has one and it is not empty.
  final String? logTail;
}

/// How much of what the person wrote goes into the report.
const _maxDescriptionChars = 3000;
const _maxLogChars = 1200;
const _maxTitleChars = 70;

/// A report travels in a web address, and browsers and GitHub accept about
/// 8,000 characters of it. Arabic is the hard case: each letter is six
/// characters once encoded. Stay well under, shortening the report to fit.
const _maxUrlLength = 7000;

/// Reads the app version, the device and the end of the error log. Anything it
/// cannot read is left out rather than failing the report.
Future<BugReportDetails> collectBugReportDetails() async {
  var appVersion = 'unknown';
  try {
    final info = await PackageInfo.fromPlatform();
    appVersion = '${info.version} (${info.buildNumber})';
  } catch (_) {}

  var device = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      device = '${info.manufacturer} ${info.model}, '
          'Android ${info.version.release} (API ${info.version.sdkInt})';
    } else if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      device = '${info.productName}, build ${info.buildNumber}';
    }
  } catch (_) {}

  return BugReportDetails(
    appVersion: appVersion,
    device: device,
    logTail: _readLogTail(),
  );
}

String? _readLogTail() {
  try {
    final file = AppLogger.file;
    if (file == null || !file.existsSync()) return null;
    final text = file.readAsStringSync().trim();
    if (text.isEmpty) return null;
    return text.length <= _maxLogChars
        ? text
        : text.substring(text.length - _maxLogChars);
  } catch (_) {
    return null;
  }
}

/// The text of the report: what the person wrote, then the facts a developer
/// needs to reproduce it.
String buildBugReportBody(String description, BugReportDetails details) {
  final text = description.trim();
  final shown = text.length <= _maxDescriptionChars
      ? text
      : '${text.substring(0, _maxDescriptionChars)}...';
  return _body(shown, details, withLog: true);
}

String _body(
  String description,
  BugReportDetails details, {
  required bool withLog,
}) {
  final buffer = StringBuffer()
    ..writeln(description)
    ..writeln()
    ..writeln('---')
    ..writeln('App version: ${details.appVersion}')
    ..writeln('Device: ${details.device}');
  final log = details.logTail;
  if (withLog && log != null) {
    buffer
      ..writeln()
      ..writeln('Recent entries from the app log:')
      ..writeln('```')
      ..writeln(log)
      ..writeln('```');
  }
  return buffer.toString();
}

/// A short title from the first line of what the person wrote.
String bugReportTitle(String description) {
  final firstLine = description
      .trim()
      .split('\n')
      .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '')
      .trim();
  final clipped = firstLine.length <= _maxTitleChars
      ? firstLine
      : '${firstLine.substring(0, _maxTitleChars)}...';
  return clipped.isEmpty ? 'Bug report' : 'Bug report: $clipped';
}

/// The page where the report is read over and sent: a new issue on the app's
/// GitHub repository, already filled in. The person reviews it in the browser
/// and presses the button there, so nothing leaves the phone without them
/// seeing it.
///
/// If the address would be too long, the log goes first and then the end of
/// the description, so a long report still opens.
Uri bugReportUri(String description, BugReportDetails details) {
  final title = bugReportTitle(description);
  final full = description.trim();
  var length =
      full.length < _maxDescriptionChars ? full.length : _maxDescriptionChars;
  var withLog = details.logTail != null;
  while (true) {
    final shown =
        length < full.length ? '${full.substring(0, length)}...' : full;
    final uri = Uri.https(
      'github.com',
      '/$githubRepoOwner/$githubRepoName/issues/new',
      {'title': title, 'body': _body(shown, details, withLog: withLog)},
    );
    if (uri.toString().length <= _maxUrlLength || length <= 50) return uri;
    if (withLog) {
      withLog = false;
    } else {
      length = length * 4 ~/ 5;
    }
  }
}

// The seams a test replaces. Each defaults to the real thing.

final bugReportDetailsProvider = Provider<Future<BugReportDetails> Function()>(
  (ref) => collectBugReportDetails,
);

/// Opens a web address; false when nothing could.
final bugReportOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => openInBrowser,
);
