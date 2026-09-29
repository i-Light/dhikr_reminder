import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dhikr_reminder/core/update/update_release.dart';

/// The switches that make Inno Setup run without a single window or prompt.
///
///  * `/CURRENTUSER` — the install this updates is per-user (see
///    [UpdateInstaller.installDirOf]); saying so keeps a silent run from
///    guessing at all-users and raising UAC.
///  * `/CLOSEAPPLICATIONS /FORCECLOSEAPPLICATIONS` — the app quits itself just
///    before, but this is what makes the install go through if it has not
///    finished yet.
const setupSilentArguments = <String>[
  '/VERYSILENT',
  '/SUPPRESSMSGBOXES',
  '/NORESTART',
  '/CLOSEAPPLICATIONS',
  '/FORCECLOSEAPPLICATIONS',
  '/CURRENTUSER',
];

/// Downloads a release's installer, checks it, and hands the machine over to
/// it.
class UpdateInstaller {
  UpdateInstaller({Directory? workDir})
      : workDir = workDir ??
            Directory(
              '${Directory.systemTemp.path}${Platform.pathSeparator}'
              'dhikr_reminder_update',
            );

  /// Where the download waits. Emptied at the start of every download, so an
  /// interrupted update never leaves more than one installer behind.
  final Directory workDir;

  /// The folder the running app was installed into by the Setup wizard, or
  /// null when it should not update itself.
  ///
  /// Two conditions, both of which have to hold:
  ///
  ///  * **`unins000.exe` sits beside the exe.** Inno writes it on install, so
  ///    this is what tells an installed copy from a `flutter run` build or an
  ///    unpacked copy. Running the installer for either would put a
  ///    second, unrelated copy in `%LOCALAPPDATA%\Programs` and leave the one
  ///    the person is using untouched.
  ///  * **The folder is writable.** An all-users install in `Program Files`
  ///    cannot be updated without admin rights, and asking for them is the
  ///    very prompt this exists to avoid.
  static Directory? installDirOf(String resolvedExecutable) {
    final dir = File(resolvedExecutable).parent;
    final uninstaller = File(
      '${dir.path}${Platform.pathSeparator}unins000.exe',
    );
    if (!uninstaller.existsSync()) return null;
    return _isWritable(dir) ? dir : null;
  }

  static bool _isWritable(Directory dir) {
    try {
      final probe = File(
        '${dir.path}${Platform.pathSeparator}.update_write_probe',
      );
      probe.writeAsBytesSync(const [0], flush: true);
      probe.deleteSync();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  /// Fetches [release]'s installer into [workDir] and returns it, verified.
  ///
  /// Throws if the download fails or does not match what GitHub said it was.
  Future<File> download(
    UpdateRelease release, {
    HttpClient? client,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    if (workDir.existsSync()) workDir.deleteSync(recursive: true);
    workDir.createSync(recursive: true);

    final target =
        File('${workDir.path}${Platform.pathSeparator}${release.assetName}');
    final partial = File('${target.path}.part');

    final http = client ?? HttpClient();
    http.connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await http.getUrl(release.assetUrl);
      request.headers
          .set(HttpHeaders.userAgentHeader, 'dhikr_reminder-updater');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException(
          'Download answered ${response.statusCode}',
          uri: release.assetUrl,
        );
      }
      final sink = partial.openWrite();
      try {
        await sink.addStream(response).timeout(timeout);
      } finally {
        await sink.close();
      }
    } finally {
      if (client == null) http.close(force: true);
    }

    final problem = await verify(partial, release);
    if (problem != null) {
      partial.deleteSync();
      throw FormatException('Downloaded installer rejected: $problem');
    }
    return partial.rename(target.path);
  }

  /// Why [file] cannot be [release]'s installer, or null if it can.
  ///
  /// The size and the SHA-256 come from GitHub's API, so this catches a
  /// truncated or corrupted download, not a compromised GitHub — that is what
  /// code signing is for, and it is not done yet.
  static Future<String?> verify(File file, UpdateRelease release) async {
    final length = await file.length();
    if (length != release.size) {
      return 'size $length, expected ${release.size}';
    }

    final head = await file.openRead(0, 2).expand((chunk) => chunk).toList();
    // Every Windows executable starts "MZ".
    if (head.length != 2 || head[0] != 0x4D || head[1] != 0x5A) {
      return 'not a Windows executable';
    }

    final expected = release.sha256;
    if (expected != null) {
      final actual = (await sha256.bind(file.openRead()).first).toString();
      if (actual != expected) return 'sha256 $actual, expected $expected';
    }
    return null;
  }

  /// The PowerShell that runs [setup] to completion, then starts [appExe]
  /// again.
  ///
  /// The relaunch is not left to the installer, because it has to happen when
  /// the install *fails* too — a reminder app that an aborted update leaves
  /// closed is one the person never notices has stopped. It is PowerShell
  /// rather than a `.cmd` because a batch file is read in the OEM code page,
  /// and a user profile path in Arabic (this app's audience) does not survive
  /// that; the command travels as UTF-16 (`-EncodedCommand`) and is
  /// Unicode-safe end to end.
  static String applyScript({required String setup, required String appExe}) {
    String q(String s) => "'${s.replaceAll("'", "''")}'";
    final switches = setupSilentArguments.map(q).join(',');
    // Progress output is silenced because stderr is a pipe into this process,
    // and by the time PowerShell writes to it the app has quit.
    return "\$ProgressPreference = 'SilentlyContinue'; "
        'try { Start-Process -FilePath ${q(setup)} '
        '-ArgumentList $switches -Wait } catch { }; '
        'Start-Process -FilePath ${q(appExe)}';
  }

  /// `-EncodedCommand` wants base64 of the script as UTF-16LE.
  static String encodeCommand(String script) {
    final bytes = <int>[];
    for (final unit in script.codeUnits) {
      bytes
        ..add(unit & 0xFF)
        ..add(unit >> 8);
    }
    return base64.encode(bytes);
  }

  /// Starts the update as a process that outlives this one. The caller is
  /// expected to quit straight after; the script waits out the install and
  /// brings the app back.
  ///
  /// Not [ProcessStartMode.detached]: that starts the child with no standard
  /// handles at all, and `powershell.exe` then never runs a line of its
  /// script. An ordinary child is not killed when its parent exits on Windows,
  /// which is all "outlives this one" needs.
  Future<void> launch(File setup, {required String appExe}) async {
    final script = applyScript(setup: setup.path, appExe: appExe);
    await Process.start(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-ExecutionPolicy',
        'Bypass',
        '-EncodedCommand',
        encodeCommand(script),
      ],
    );
  }
}
