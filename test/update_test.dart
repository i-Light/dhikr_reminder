import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dhikr_reminder/core/update/update_controller.dart';
import 'package:dhikr_reminder/core/update/update_installer.dart';
import 'package:dhikr_reminder/core/update/update_release.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _releaseJson({
  String tag = 'v0.2.0',
  bool draft = false,
  bool prerelease = false,
  List<Map<String, dynamic>>? assets,
}) {
  return {
    'tag_name': tag,
    'draft': draft,
    'prerelease': prerelease,
    'assets': assets ??
        [
          {
            'name': 'dhikr_reminder-0.2.0-windows-x64.zip',
            'size': 10,
            'browser_download_url':
                'https://github.com/i-Light/dhikr_reminder/releases/download/v0.2.0/dhikr_reminder-0.2.0-windows-x64.zip',
          },
          {
            'name': 'dhikr_reminder-0.2.0-setup.exe',
            'size': 1234,
            'browser_download_url':
                'https://github.com/i-Light/dhikr_reminder/releases/download/v0.2.0/dhikr_reminder-0.2.0-setup.exe',
            'digest': 'sha256:ABCDEF',
          },
        ],
  };
}

/// A file that looks enough like an installer to pass [UpdateInstaller.verify].
List<int> _fakeExe(int length) => [0x4D, 0x5A, ...List.filled(length - 2, 7)];

void main() {
  group('AppVersion', () {
    test('parses tags and pubspec versions alike', () {
      expect(AppVersion.tryParse('v1.2.3'), const AppVersion(1, 2, 3));
      expect(AppVersion.tryParse('0.1.0'), const AppVersion(0, 1, 0));
      expect(AppVersion.tryParse('0.1.0+4'), const AppVersion(0, 1, 0));
      expect(AppVersion.tryParse('1.0.0-beta.1'), const AppVersion(1, 0, 0));
    });

    test('rejects what is not a version', () {
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('latest'), isNull);
      expect(AppVersion.tryParse('1.2'), isNull);
    });

    test('compares numerically, not as text', () {
      expect(
          AppVersion.tryParse('0.10.0')!
              .isNewerThan(AppVersion.tryParse('0.9.9')!),
          isTrue);
      expect(
          AppVersion.tryParse('1.0.0')!
              .isNewerThan(AppVersion.tryParse('0.99.99')!),
          isTrue);
      expect(
          AppVersion.tryParse('0.1.1')!
              .isNewerThan(AppVersion.tryParse('0.1.0')!),
          isTrue);
    });

    test('an equal or older version is not newer', () {
      expect(
          AppVersion.tryParse('0.1.0')!
              .isNewerThan(AppVersion.tryParse('0.1.0')!),
          isFalse);
      expect(
          AppVersion.tryParse('0.1.0')!
              .isNewerThan(AppVersion.tryParse('0.2.0')!),
          isFalse);
    });
  });

  group('UpdateRelease.fromGithubJson', () {
    test('picks the setup exe over the zip and reads its digest', () {
      final release = UpdateRelease.fromGithubJson(_releaseJson())!;

      expect(release.version, const AppVersion(0, 2, 0));
      expect(release.assetName, 'dhikr_reminder-0.2.0-setup.exe');
      expect(release.size, 1234);
      // Lowercased, so it compares against Dart's hex output.
      expect(release.sha256, 'abcdef');
    });

    test('a missing digest is not an error', () {
      final json = _releaseJson(assets: [
        {
          'name': 'dhikr_reminder-0.2.0-setup.exe',
          'size': 5,
          'browser_download_url':
              'https://github.com/i-Light/dhikr_reminder/releases/download/v0.2.0/dhikr_reminder-0.2.0-setup.exe',
        },
      ]);

      expect(UpdateRelease.fromGithubJson(json)!.sha256, isNull);
    });

    test('ignores drafts and pre-releases', () {
      expect(UpdateRelease.fromGithubJson(_releaseJson(draft: true)), isNull);
      expect(
          UpdateRelease.fromGithubJson(_releaseJson(prerelease: true)), isNull);
    });

    test('ignores a release with no installer attached', () {
      final zipOnly = _releaseJson(assets: [
        {
          'name': 'dhikr_reminder-0.2.0-windows-x64.zip',
          'size': 10,
          'browser_download_url':
              'https://github.com/x/y/releases/download/v0.2.0/a.zip',
        },
      ]);

      expect(UpdateRelease.fromGithubJson(zipOnly), isNull);
    });

    test('ignores a tag that is not a version', () {
      expect(
          UpdateRelease.fromGithubJson(_releaseJson(tag: 'nightly')), isNull);
    });

    test('refuses an installer served from anywhere but github.com over https',
        () {
      for (final url in [
        'http://github.com/i-Light/dhikr_reminder/releases/download/v0.2.0/a-setup.exe',
        'https://evil.example/a-setup.exe',
        'https://github.com.evil.example/a-setup.exe',
      ]) {
        final json = _releaseJson(assets: [
          {'name': 'a-setup.exe', 'size': 5, 'browser_download_url': url},
        ]);
        expect(UpdateRelease.fromGithubJson(json), isNull, reason: url);
      }
    });
  });

  group('UpdateInstaller.verify', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('dhikr_update_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    UpdateRelease releaseFor(List<int> bytes, {String? sha}) => UpdateRelease(
          version: const AppVersion(0, 2, 0),
          assetName: 'a-setup.exe',
          assetUrl: Uri.parse('https://github.com/x/y/a-setup.exe'),
          size: bytes.length,
          sha256: sha,
        );

    File write(List<int> bytes) {
      final file = File('${dir.path}/a-setup.exe')..writeAsBytesSync(bytes);
      return file;
    }

    test('accepts a file that matches size and digest', () async {
      final bytes = _fakeExe(64);
      final file = write(bytes);

      expect(
          await UpdateInstaller.verify(
              file, releaseFor(bytes, sha: sha256.convert(bytes).toString())),
          isNull);
    });

    test('accepts a file when GitHub gave no digest', () async {
      final bytes = _fakeExe(64);

      expect(await UpdateInstaller.verify(write(bytes), releaseFor(bytes)),
          isNull);
    });

    test('rejects a truncated download', () async {
      final bytes = _fakeExe(64);
      final file = write(bytes.sublist(0, 40));

      expect(await UpdateInstaller.verify(file, releaseFor(bytes)),
          contains('size'));
    });

    test('rejects a file that is not an executable', () async {
      final bytes = List.filled(64, 1);

      expect(await UpdateInstaller.verify(write(bytes), releaseFor(bytes)),
          contains('executable'));
    });

    test('rejects a digest mismatch', () async {
      final bytes = _fakeExe(64);
      final other = sha256.convert(_fakeExe(65)).toString();

      expect(
          await UpdateInstaller.verify(
              write(bytes), releaseFor(bytes, sha: other)),
          contains('sha256'));
    });
  });

  group('UpdateInstaller.download', () {
    late Directory dir;
    late HttpServer server;
    late List<int> served;
    var status = HttpStatus.ok;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('dhikr_update_test');
      served = _fakeExe(4096);
      status = HttpStatus.ok;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(server.forEach((request) async {
        request.response.statusCode = status;
        if (status == HttpStatus.ok) request.response.add(served);
        await request.response.close();
      }));
    });
    tearDown(() async {
      await server.close(force: true);
      dir.deleteSync(recursive: true);
    });

    UpdateRelease release({String? sha, int? size}) => UpdateRelease(
          version: const AppVersion(0, 2, 0),
          assetName: 'a-setup.exe',
          assetUrl: Uri.parse('http://127.0.0.1:${server.port}/a-setup.exe'),
          size: size ?? served.length,
          sha256: sha,
        );

    test('saves the verified installer under its own name', () async {
      final installer = UpdateInstaller(workDir: Directory('${dir.path}/work'));

      final file = await installer.download(
        release(sha: sha256.convert(served).toString()),
      );

      expect(file.path, endsWith('a-setup.exe'));
      expect(file.readAsBytesSync(), served);
      expect(
        Directory('${dir.path}/work').listSync().map((e) => e.path),
        [file.path],
        reason: 'no .part file may be left behind',
      );
    });

    test('clears an earlier download out of the way', () async {
      final work = Directory('${dir.path}/work')..createSync();
      File('${work.path}/old-setup.exe').writeAsBytesSync([1]);

      await UpdateInstaller(workDir: work).download(release());

      expect(File('${work.path}/old-setup.exe').existsSync(), isFalse);
    });

    test('throws, and keeps nothing, when the bytes do not match', () async {
      final work = Directory('${dir.path}/work');

      await expectLater(
        UpdateInstaller(workDir: work).download(release(sha: '00' * 32)),
        throwsA(isA<FormatException>()),
      );
      expect(work.listSync(), isEmpty);
    });

    test('throws on an HTTP error', () async {
      status = HttpStatus.notFound;

      await expectLater(
        UpdateInstaller(workDir: Directory('${dir.path}/work'))
            .download(release()),
        throwsA(isA<HttpException>()),
      );
    });
  });

  group('UpdateInstaller.installDirOf', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('dhikr_update_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('is the exe folder when the Setup wizard put an uninstaller there',
        () {
      File('${dir.path}/unins000.exe').writeAsBytesSync([0]);

      expect(
        UpdateInstaller.installDirOf('${dir.path}/dhikr_reminder.exe')?.path,
        dir.path,
      );
      expect(
        dir.listSync().map((e) => e.path.split(RegExp(r'[\\/]')).last),
        ['unins000.exe'],
        reason: 'the writability probe must clean up after itself',
      );
    });

    test('is null for a portable copy or a dev build', () {
      expect(UpdateInstaller.installDirOf('${dir.path}/dhikr_reminder.exe'),
          isNull);
    });
  });

  group('UpdateInstaller.applyScript', () {
    test('runs the installer silently, then starts the app', () {
      final script = UpdateInstaller.applyScript(
        setup: r'C:\Temp\x\a-setup.exe',
        appExe: r'C:\Apps\dhikr_reminder.exe',
      );

      expect(script, contains(r"'C:\Temp\x\a-setup.exe'"));
      expect(script, contains("'/VERYSILENT'"));
      expect(script, contains('-Wait'));
      // The relaunch is outside the try, so it happens after a failed install.
      expect(script.indexOf('Start-Process -FilePath \'C:\\Apps'),
          greaterThan(script.indexOf('}')));
    });

    test('a quote in a path cannot break out of its string', () {
      final script = UpdateInstaller.applyScript(
        setup: r"C:\Users\O'Brien\a-setup.exe",
        appExe: r'C:\Apps\dhikr_reminder.exe',
      );

      expect(script, contains(r"'C:\Users\O''Brien\a-setup.exe'"));
    });

    test('encodeCommand round-trips non-ASCII paths as UTF-16LE', () {
      const script = r"Start-Process 'C:\Users\مصطفى\a.exe'";

      final bytes = base64.decode(UpdateInstaller.encodeCommand(script));
      final units = [
        for (var i = 0; i < bytes.length; i += 2)
          bytes[i] | (bytes[i + 1] << 8),
      ];

      expect(String.fromCharCodes(units), script);
    });
  });

  test('the update notifier survives with nothing listening to it', () async {
    // The reminder scheduler needs a widget to keep it mounted; this one is
    // only ever read from `main`, so it must not be disposed under its timer.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(updateProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(
        identical(container.read(updateProvider.notifier), notifier), isTrue);
    expect(container.read(updateProvider).phase, UpdatePhase.idle);
  });
}
