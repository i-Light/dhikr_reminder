import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/toast/dust_particles_overlay.dart';
import 'package:dhikr_reminder/core/toast/outer_glow.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the real scheduler so its `Timer.periodic` never starts
/// inside a test — a timer still pending at the end of `testWidgets` fails
/// the test. The overlay only watches this provider for its side effects, so
/// a no-op `build` is the whole contract.
class _QuietScheduler extends DhikrReminderScheduler {
  @override
  DateTime? build() => null;
}

/// Mounts [DhikrReminderOverlay] over a bare home and returns the container
/// driving it.
Future<ProviderContainer> _pumpOverlay(WidgetTester tester) async {
  // Mirror the real desktop window (windows/runner/main.cpp opens 1280×800)
  // so the card lays out at the width it ships at instead of the 800×600
  // test default, which squeezes the frame's tip row into an overflow.
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dhikrReminderSchedulerProvider.overrideWith(_QuietScheduler.new),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          container = ref.container;
          return const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DhikrReminderOverlay(child: SizedBox.expand()),
          );
        },
      ),
    ),
  );
  // One pump to build, one to let the settings load settle.
  await tester.pump();
  await tester.pump();
  return container;
}

/// The [SnapshotWidget] wrapping the reminder card itself — the switcher
/// also wraps its empty placeholder, so the child type is what tells them
/// apart. Null once the card's exit has finished and its entry is gone.
SnapshotWidget? _cardSnapshot(WidgetTester tester) {
  return tester
      .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
      .where((widget) =>
          widget.child?.runtimeType.toString() == '_DhikrReminderCard')
      .firstOrNull;
}

bool _painterIsPresent<T>(WidgetTester tester) {
  return tester.widgetList<CustomPaint>(find.byType(CustomPaint)).any(
        (paint) => paint.painter is T,
      );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'dismissing the reminder freezes the card to a snapshot and '
      'fades the image out', (tester) async {
    final container = await _pumpOverlay(tester);
    container.read(activeDhikrReminderProvider.notifier).show(
          const DhikrEntry(id: 1, name: 'SubhanAllah', amount: 33),
        );
    await tester.pump(); // build the card
    await tester.pump(const Duration(milliseconds: 250)); // entrance over

    final before = _cardSnapshot(tester);
    expect(
      before,
      isNotNull,
      reason: 'every switcher child is wrapped in the snapshot transition',
    );
    expect(
      before!.controller.allowSnapshotting,
      isFalse,
      reason: 'the card renders live until its exit starts',
    );
    expect(
      _painterIsPresent<AmbientGlowPainter>(tester),
      isTrue,
      reason: 'glow layer 1 draws from the baked sprite store',
    );
    expect(
      _painterIsPresent<PulseGlowPainter>(tester),
      isTrue,
      reason: 'glow layer 1b draws from the baked sprite store',
    );

    // A tap runs the bump, the glow pulse and the count roll — the frames
    // the baked glow has to survive while everything animates.
    container.read(activeDhikrReminderProvider.notifier).increment();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    container.read(activeDhikrReminderProvider.notifier).dismiss();
    await tester.pump(); // exit frame one: the card freezes

    final during = _cardSnapshot(tester);
    expect(during, isNotNull);
    expect(
      during!.controller.allowSnapshotting,
      isTrue,
      reason: 'the exit captures the card once the reverse transition begins',
    );

    await tester.pump(const Duration(milliseconds: 100)); // mid-exit
    await tester.pump(const Duration(milliseconds: 150)); // exit (200ms) over

    expect(
      _cardSnapshot(tester),
      isNull,
      reason: "the card's switcher entry is gone once the fade finishes",
    );
    expect(tester.takeException(), isNull);

    // Unmount so no ticker or provider outlives the test.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HolyDustBackground animates its halos without a mask filter',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HolyDustBackground(particleCount: 15)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
