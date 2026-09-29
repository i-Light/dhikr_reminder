import 'dart:async';
import 'dart:io';

import 'package:dhikr_reminder/core/update/update_controller.dart';
import 'package:dhikr_reminder/core/update/update_installer.dart';
import 'package:dhikr_reminder/core/update/update_release.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInstaller extends UpdateInstaller {
  int downloads = 0;
  final launched = <File>[];

  @override
  Future<File> download(
    UpdateRelease release, {
    HttpClient? client,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    downloads++;
    return File('${Directory.systemTemp.path}/${release.assetName}')
      ..writeAsBytesSync([0x4D, 0x5A]);
  }

  @override
  Future<void> launch(File setup, {required String appExe}) async {
    launched.add(setup);
  }
}

UpdateRelease _release(String version) => UpdateRelease(
      version: AppVersion.tryParse(version)!,
      assetName: 'dhikr_reminder-$version-setup.exe',
      assetUrl: Uri.parse('https://github.com/x/y/a-setup.exe'),
      size: 2,
    );

void main() {
  late _FakeInstaller installer;
  late int quits;
  late Future<UpdateRelease?> Function() source;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installer = _FakeInstaller();
    quits = 0;
    source = () async => _release('0.2.0');
  });

  Future<ProviderContainer> build({bool canSelfUpdate = true}) async {
    final container = ProviderContainer(
      overrides: [
        updateSourceProvider.overrideWithValue(() => source()),
        updateInstallerProvider.overrideWithValue(installer),
        updateInstallDirProvider.overrideWithValue(
          canSelfUpdate ? Directory.systemTemp : null,
        ),
        updateCurrentVersionProvider.overrideWithValue(
          () async => const AppVersion(0, 1, 0),
        ),
        updateQuitProvider.overrideWithValue(() async => quits++),
      ],
    );
    addTearDown(container.dispose);
    // Let the notifier read its version and saved setting.
    container.read(updateProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container;
  }

  test('a newer release is downloaded, installed, and the app quits', () async {
    final container = await build();

    await container.read(updateProvider.notifier).checkNow();

    expect(installer.downloads, 1);
    expect(installer.launched, hasLength(1));
    expect(quits, 1);
    expect(container.read(updateProvider).latestVersion,
        const AppVersion(0, 2, 0));
  });

  test('the same version is left alone', () async {
    source = () async => _release('0.1.0');
    final container = await build();

    await container.read(updateProvider.notifier).checkNow();

    final state = container.read(updateProvider);
    expect(installer.downloads, 0);
    expect(quits, 0);
    expect(state.updateAvailable, isFalse);
    expect(state.lastChecked, isNotNull);
    expect(state.phase, UpdatePhase.idle);
  });

  test('with automatic updates off it only reports, until told to install',
      () async {
    final container = await build();
    final notifier = container.read(updateProvider.notifier);
    await notifier.setAutoUpdate(false);

    await notifier.checkNow();

    expect(installer.downloads, 0);
    expect(container.read(updateProvider).updateAvailable, isTrue);

    await notifier.installNow();

    expect(installer.downloads, 1);
    expect(installer.launched, hasLength(1));
    expect(quits, 1);
  });

  test('the automatic-updates choice is saved', () async {
    final container = await build();
    await container.read(updateProvider.notifier).setAutoUpdate(false);

    expect(
        (await SharedPreferences.getInstance())
            .getBool('dhikr_reminder.update.auto'),
        isFalse);
  });

  test('a copy that cannot update itself is told, and never touched', () async {
    final container = await build(canSelfUpdate: false);
    final notifier = container.read(updateProvider.notifier);

    await notifier.checkNow();
    await notifier.installNow();

    final state = container.read(updateProvider);
    expect(state.updateAvailable, isTrue);
    expect(state.canSelfUpdate, isFalse);
    expect(installer.downloads, 0);
    expect(quits, 0);
  });

  test('a failed check is remembered as failed and leaves the updater free',
      () async {
    source = () async => throw const SocketException('offline');
    final container = await build();

    await container.read(updateProvider.notifier).checkNow();

    final state = container.read(updateProvider);
    expect(state.failed, isTrue);
    expect(state.phase, UpdatePhase.idle);
    expect(quits, 0);

    // ...and the next successful check clears it.
    source = () async => _release('0.1.0');
    await container.read(updateProvider.notifier).checkNow();
    expect(container.read(updateProvider).failed, isFalse);
  });

  test('an update waits while a reminder is on screen, and installNow does not',
      () async {
    final container = await build();
    container
        .read(activeDhikrReminderProvider.notifier)
        .show(const DhikrEntry(id: 1, name: 'x'));
    final notifier = container.read(updateProvider.notifier);

    final check = notifier.checkNow();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(container.read(updateProvider).phase, UpdatePhase.waitingForIdle);
    expect(quits, 0);

    unawaited(notifier.installNow());
    await check;

    expect(quits, 1);
    expect(installer.downloads, 1,
        reason: 'the download made while waiting is reused');
  });
}
