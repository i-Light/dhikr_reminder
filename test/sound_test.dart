import 'dart:typed_data';

import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/sound/chime.dart';
import 'package:dhikr_reminder/features/sound/chime_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeChime implements ChimePlayer {
  int played = 0;
  bool? prepared;

  @override
  Future<void> play() async => played++;

  @override
  Future<void> prepare({required bool enabled}) async => prepared = enabled;
}

Future<(ProviderContainer, _FakeChime)> _rig({required bool soundOn}) async {
  SharedPreferences.setMockInitialValues({
    'dhikr_reminder.sound.on': soundOn,
  });
  final chime = _FakeChime();
  final container = ProviderContainer(
    overrides: [chimePlayerProvider.overrideWithValue(chime)],
  );
  addTearDown(container.dispose);
  container.read(dhikrSettingsProvider);
  while (!container.read(dhikrSettingsProvider).isLoaded) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  return (container, chime);
}

void main() {
  group('the chime sound', () {
    final wav = buildChimeWav();
    final bytes = ByteData.sublistView(wav);

    test('is a valid mono 16-bit WAV file', () {
      String text(int at, int n) => String.fromCharCodes(wav.sublist(at, at + n));
      expect(text(0, 4), 'RIFF');
      expect(text(8, 4), 'WAVE');
      expect(text(12, 4), 'fmt ');
      expect(text(36, 4), 'data');
      expect(bytes.getUint16(20, Endian.little), 1); // PCM
      expect(bytes.getUint16(22, Endian.little), 1); // mono
      expect(bytes.getUint32(24, Endian.little), 22050);
      expect(bytes.getUint16(34, Endian.little), 16);
      // The sizes in the header match the bytes that follow.
      expect(bytes.getUint32(4, Endian.little), wav.length - 8);
      expect(bytes.getUint32(40, Endian.little), wav.length - 44);
    });

    test('is short and soft: well under full volume, and not long', () {
      final frames = (wav.length - 44) ~/ 2;
      var peak = 0;
      for (var i = 0; i < frames; i++) {
        final sample = bytes.getInt16(44 + i * 2, Endian.little).abs();
        if (sample > peak) peak = sample;
      }
      expect(peak, greaterThan(2000), reason: 'it must be audible');
      expect(peak, lessThan(32767 * 0.5), reason: 'and never startling');
      expect(frames / 22050, inInclusiveRange(0.4, 1.0));
    });

    test('begins and ends in silence, so it cannot click', () {
      final frames = (wav.length - 44) ~/ 2;
      expect(bytes.getInt16(44, Endian.little).abs(), lessThan(50));
      expect(bytes.getInt16(44 + (frames - 1) * 2, Endian.little), 0);
    });

    test('is the same every time', () {
      expect(buildChimeWav(), wav);
    });
  });

  group('when it plays', () {
    test('on the last count of a dhikr, once, if sound is on', () async {
      final (container, chime) = await _rig(soundOn: true);
      final reminders = container.read(activeDhikrReminderProvider.notifier);

      reminders.show(const DhikrEntry(id: 1, name: 'x', amount: 3));
      reminders.increment();
      reminders.increment();
      expect(chime.played, 0, reason: 'not before the last count');
      reminders.increment();
      expect(chime.played, 1);
      reminders.increment(); // already complete: ignored
      expect(chime.played, 1);
      reminders.dismiss();
    });

    test('never, by default', () async {
      final (container, chime) = await _rig(soundOn: false);
      final reminders = container.read(activeDhikrReminderProvider.notifier);

      reminders.show(const DhikrEntry(id: 1, name: 'x', amount: 1));
      reminders.increment();

      expect(container.read(activeDhikrReminderProvider)!.isComplete, isTrue);
      expect(chime.played, 0);
      reminders.dismiss();
    });

    test('and the switch is remembered', () async {
      final (container, _) = await _rig(soundOn: false);
      expect(container.read(dhikrSettingsProvider).soundOn, isFalse);

      await container.read(dhikrSettingsProvider.notifier).updateSoundOn(true);

      expect(container.read(dhikrSettingsProvider).soundOn, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dhikr_reminder.sound.on'), isTrue);
    });
  });
}
