import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:dhikr_reminder/platform/autostart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAutostart implements AutostartService {
  bool enabled = false;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
}

void main() {
  test('the switch reads and writes through the platform service', () async {
    final fake = _FakeAutostart();
    final container = ProviderContainer(overrides: [
      autostartServiceProvider.overrideWithValue(fake),
    ]);
    addTearDown(container.dispose);

    expect(await container.read(autostartProvider.future), isFalse);

    await container.read(autostartProvider.notifier).set(true);

    expect(fake.enabled, isTrue);
    expect(container.read(autostartProvider).value, isTrue);
  });

  test('without the capability the service does nothing', () async {
    final container = ProviderContainer(overrides: [
      appPlatformProvider
          .overrideWithValue(const AppPlatform(PlatformKind.android)),
    ]);
    addTearDown(container.dispose);

    final service = container.read(autostartServiceProvider);
    await service.setEnabled(true);

    expect(await service.isEnabled(), isFalse);
  });
}
