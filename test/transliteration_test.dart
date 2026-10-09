import 'dart:math';

import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/core/toast/dhikr_fit_text.dart';
import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/application/transliteration_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_english_data.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_transliteration_data.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_display.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_english.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/library_popups.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_host.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_overlay.dart';

/// "Subhanallah, wal-hamdu lillah, wallahu akbar": short, a reminder, and with a
/// transliteration.
const _tasbeehId = 'd87b68ccd23';

/// The reminder-sized entries that are explanation (a hadith told, the way a
/// dream is to be handled) rather than words to say, so have no transliteration.
const _explanationIds = {
  'd884987d3e2',
  'd296ecf4fbe',
  'd93dd590bdb',
  'd85720022b0',
  'db56291d0be',
  'dc6aed59f8e',
  'dc309696da5',
};

DhikrEntry _linked(String libraryId, {int id = 1, int goal = 0}) {
  final item = libraryItemById(libraryId)!;
  return DhikrEntry(
    id: id,
    name: item.text,
    amount: 3,
    dailyGoal: goal,
    libraryId: libraryId,
  );
}

Widget _app(Widget home, {String lang = 'en'}) => MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('resolveDhikrDisplay', () {
    test('shows both when both are on', () {
      final display = resolveDhikrDisplay(
        arabic: 'ar',
        transliteration: 'la',
        showTransliteration: true,
        showArabic: true,
      );
      expect(display.arabic, 'ar');
      expect(display.transliteration, 'la');
    });

    test('hiding the Arabic leaves the transliteration alone', () {
      final display = resolveDhikrDisplay(
        arabic: 'ar',
        transliteration: 'la',
        showTransliteration: true,
        showArabic: false,
      );
      expect(display.hasArabic, isFalse);
      expect(display.transliteration, 'la');
    });

    test('never leaves a card empty', () {
      // No transliteration to read instead.
      expect(
        resolveDhikrDisplay(
          arabic: 'ar',
          transliteration: null,
          showTransliteration: true,
          showArabic: false,
        ).arabic,
        'ar',
      );
      // The transliteration is switched off.
      expect(
        resolveDhikrDisplay(
          arabic: 'ar',
          transliteration: 'la',
          showTransliteration: false,
          showArabic: false,
        ).arabic,
        'ar',
      );
      // A blank one is none.
      expect(
        resolveDhikrDisplay(
          arabic: 'ar',
          transliteration: '  ',
          showTransliteration: true,
          showArabic: false,
        ).arabic,
        'ar',
      );
    });

    test('with the transliteration off only the Arabic shows', () {
      final display = resolveDhikrDisplay(
        arabic: 'ar',
        transliteration: 'la',
        showTransliteration: false,
        showArabic: true,
      );
      expect(display.arabic, 'ar');
      expect(display.hasTransliteration, isFalse);
    });
  });

  group('the transliteration data', () {
    test('belongs to library entries', () {
      for (final id in dhikrTransliterations.keys) {
        expect(libraryItemById(id), isNotNull, reason: id);
      }
    });

    test('covers every reminder that is something to say', () {
      for (final item in dhikrLibrary) {
        if (!item.isRemindable || _explanationIds.contains(item.id)) continue;
        expect(dhikrTransliterations[item.id], isNotNull, reason: item.text);
      }
    });

    test('has none for the explanations', () {
      for (final id in _explanationIds) {
        expect(libraryItemById(id), isNotNull, reason: id);
        expect(dhikrTransliterations[id], isNull, reason: id);
      }
    });

    test('is plain letters, one scheme, no stray symbols', () {
      for (final entry in dhikrTransliterations.entries) {
        final text = entry.value;
        expect(text.trim(), text, reason: entry.key);
        expect(text, isNotEmpty, reason: entry.key);
        final plain = text.codeUnits.every(
          (c) => (c >= 0x20 && c <= 0x7E) || c == 0x0A,
        );
        expect(plain, isTrue, reason: entry.key);
        expect(text.contains('  '), isFalse, reason: entry.key);
      }
    });

    test('keeps the lines of the Arabic it goes with', () {
      for (final entry in dhikrTransliterations.entries) {
        final arabic = libraryItemById(entry.key)!.text;
        expect(
          '\n'.allMatches(entry.value).length,
          '\n'.allMatches(arabic).length,
          reason: arabic,
        );
      }
    });

    test('is found from a saved reminder by its library link', () {
      expect(
        _linked(_tasbeehId).transliteration,
        dhikrTransliterations[_tasbeehId],
      );
      // One typed in by hand before the library took over has none.
      expect(
        const DhikrEntry(id: 9, name: 'سبحان الله').transliteration,
        isNull,
      );
    });
  });

  group('the English wording', () {
    /// Entries that are duas themselves, long ones included: they stay Arabic
    /// (with no transliteration either), and so have no English text.
    const stayArabic = {
      'da343f00d5c',
      'd40cb0e62f1',
      'd3b31404057',
      'd4f4617d5bb',
    };
    bool hasArabic(String text) =>
        text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

    test('belongs to library entries', () {
      for (final id in dhikrEnglishData.keys) {
        expect(libraryItemById(id), isNotNull, reason: id);
      }
    });

    test('has a version for every lead-in, source and note', () {
      for (final item in dhikrLibrary) {
        final english = dhikrEnglishData[item.id];
        if (item.subtitle != null &&
            !dhikrLeadInPhrases.containsKey(item.subtitle)) {
          expect(english?.subtitle, isNotNull, reason: item.subtitle);
        }
        if (item.reference != null) {
          expect(english?.reference, isNotNull, reason: item.reference);
        }
        if (item.description != null) {
          expect(english?.description, isNotNull, reason: item.description);
        }
      }
    });

    test('is English, with only the two phrases that stay Arabic', () {
      final emDash = String.fromCharCode(0x2014);
      for (final entry in dhikrEnglishData.entries) {
        final texts = [
          entry.value.subtitle,
          entry.value.reference,
          entry.value.description,
          entry.value.text,
        ];
        for (final original in texts) {
          if (original == null) continue;
          var text = original;
          for (final phrase in dhikrLeadInPhrases.keys) {
            text = text.replaceAll(phrase, '');
          }
          expect(hasArabic(text), isFalse, reason: original);
          expect(text.contains(emDash), isFalse, reason: original);
        }
      }
    });

    test('translates every explanation, and leaves the duas', () {
      for (final item in dhikrLibrary) {
        if (dhikrTransliterations.containsKey(item.id)) continue;
        final text = dhikrEnglishData[item.id]?.text;
        if (stayArabic.contains(item.id)) {
          expect(text, isNull, reason: item.id);
        } else {
          expect(text, isNotNull, reason: item.subtitle ?? item.id);
        }
      }
    });

    test('takes the place of the transliteration under an explanation', () {
      final id = _explanationIds.first;
      expect(libraryTransliteration(id), dhikrEnglishData[id]!.text);
      // A dhikr keeps its transliteration.
      expect(
        libraryTransliteration(_tasbeehId),
        dhikrTransliterations[_tasbeehId],
      );
    });

    test('leaves no Arabic in a lead-in once the Arabic is off', () {
      const lead = 'Surah Al-Baqarah: أعوذ بالله من الشيطان الرجيم';
      expect(leadInFor(lead, showArabic: true), lead);
      expect(
        leadInFor(lead, showArabic: false),
        "Surah Al-Baqarah: A'udhu billahi minash-shaytanir-rajim",
      );
      expect(
        leadInFor('بسم الله الرحمن الرحيم', showArabic: false),
        'Bismillahir-rahmanir-rahim',
      );
    });

    test('is searchable in English, and the Arabic still is', () {
      final tasbeeh = libraryItemById(_tasbeehId)!;
      expect(libraryMatchesEnglishQuery(tasbeeh, 'subhanallah'), isTrue);
      expect(libraryMatchesEnglishQuery(tasbeeh, 'zzzz qqqq'), isFalse);
      expect(libraryMatchesEnglishQuery(tasbeeh, ''), isTrue);

      final kursi = libraryItemById('d17424625ae')!;
      expect(libraryMatchesEnglishQuery(kursi, 'baqarah 255'), isTrue);
      expect(kursi.matchesQuery('البقرة'), isTrue);
    });
  });

  group('the transliteration', () {
    test('follows the language: never in Arabic, always in English', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(showTransliterationProvider, (_, __) {});
      await pumpEventQueue();

      // Arabic is the app's own language.
      expect(container.read(showTransliterationProvider), isFalse);

      await container.read(localeProvider.notifier).toggle();
      expect(container.read(showTransliterationProvider), isTrue);

      await container.read(localeProvider.notifier).toggle();
      expect(container.read(showTransliterationProvider), isFalse);
    });

    test('the Arabic switches are remembered, and start on', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(dhikrLibraryProvider).showArabic, isTrue);
      expect(container.read(dhikrSettingsProvider).overlayShowArabic, isTrue);
      await pumpEventQueue();

      await container.read(dhikrLibraryProvider.notifier).toggleArabic();
      await container
          .read(dhikrSettingsProvider.notifier)
          .updateOverlayShowArabic(false);

      final again = ProviderContainer();
      addTearDown(again.dispose);
      again.read(dhikrLibraryProvider);
      again.read(dhikrSettingsProvider);
      await pumpEventQueue();
      expect(again.read(dhikrLibraryProvider).showArabic, isFalse);
      expect(again.read(dhikrSettingsProvider).overlayShowArabic, isFalse);
    });
  });

  group('the reminder plan', () {
    test('carries the transliteration for the card to show', () {
      final plan = planReminders(
        now: DateTime(2026, 1, 1),
        interval: const Duration(minutes: 30),
        entries: [
          _linked(_tasbeehId),
          const DhikrEntry(id: 2, name: 'الحمد لله'),
        ],
        useChance: false,
        random: Random(3),
        count: 40,
        showTransliteration: true,
      );

      final linked = plan.firstWhere((p) => p.entry.id == 1);
      expect(linked.transliteration, dhikrTransliterations[_tasbeehId]);
      expect(linked.toOverlayMap()['translit'], linked.transliteration);
      // Whether the Arabic is kept is the card's to read when it appears.
      expect(linked.toOverlayMap().containsKey('hideArabic'), isFalse);

      final typed = plan.firstWhere((p) => p.entry.id == 2);
      expect(typed.transliteration, isNull);
      expect(typed.toOverlayMap()['translit'], '');
    });

    test('has none when the transliteration is off', () {
      final plan = planReminders(
        now: DateTime(2026, 1, 1),
        interval: const Duration(minutes: 30),
        entries: [_linked(_tasbeehId)],
        useChance: false,
        random: Random(3),
        count: 3,
      );
      expect(plan.every((p) => p.transliteration == null), isTrue);
    });

    test('the syncer hands the overlay the Arabic switch', () async {
      final overlay = FakeOverlay(allowed: true);
      final syncer = MobileReminderSyncer(overlay, random: Random(1));
      await syncer.sync(
        settings: DhikrSettings(
          entries: [_linked(_tasbeehId)],
          intervalMinutes: 30,
          isLoaded: true,
          overlayShowArabic: false,
        ),
        locale: const Locale('en'),
        showTransliteration: true,
      );

      expect(overlay.scheduled, isNotEmpty);
      expect(overlay.arabicHidden, isTrue);
      expect(
        overlay.scheduled!.first.transliteration,
        dhikrTransliterations[_tasbeehId],
      );
    });
  });

  group('the library card', () {
    final item = libraryItemById(_tasbeehId)!;
    final latin = dhikrTransliterations[_tasbeehId]!;

    Future<void> pump(
      WidgetTester tester, {
      required DhikrItem item,
      bool translit = true,
      bool arabic = true,
    }) async {
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: DhikrLibraryCard(
              item: item,
              view: DhikrLibraryView(showArabic: arabic),
              showTransliteration: translit,
            ),
          ),
        ),
      );
    }

    testWidgets('puts the transliteration under the Arabic', (tester) async {
      await pump(tester, item: item);

      expect(find.text(item.text), findsOneWidget);
      expect(find.text(latin), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(latin)).dy,
        greaterThan(tester.getBottomLeft(find.text(item.text)).dy - 1),
      );
    });

    testWidgets('shows only the Arabic when the transliteration is off', (
      tester,
    ) async {
      await pump(tester, item: item, translit: false);

      expect(find.text(item.text), findsOneWidget);
      expect(find.text(latin), findsNothing);
    });

    testWidgets('the Arabic switch hides the Arabic and keeps the Latin', (
      tester,
    ) async {
      await pump(tester, item: item, arabic: false);

      expect(find.text(item.text), findsNothing);
      expect(find.text(latin), findsOneWidget);
    });

    testWidgets('an entry with no transliteration keeps its Arabic', (
      tester,
    ) async {
      // A long dua that has neither a transliteration nor an English text.
      final explanation = libraryItemById('d3b31404057')!;
      await pump(tester, item: explanation, arabic: false);

      expect(find.text(explanation.text), findsOneWidget);
    });
  });

  group('the library card around the dhikr', () {
    final kursi = libraryItemById('d17424625ae')!;
    final english = dhikrEnglishData[kursi.id]!;

    Future<void> pump(
      WidgetTester tester, {
      required DhikrItem item,
      bool inEnglish = true,
      bool arabic = true,
    }) async {
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: DhikrLibraryCard(
              item: item,
              view: DhikrLibraryView(showArabic: arabic),
              showTransliteration: inEnglish,
            ),
          ),
        ),
      );
    }

    testWidgets('is in English in English, the dhikr phrases aside', (
      tester,
    ) async {
      await pump(tester, item: kursi);

      expect(find.text('[${english.reference}]'), findsOneWidget);
      expect(find.text(english.description!), findsOneWidget);
      expect(find.text(kursi.reference!), findsNothing);
      expect(find.text(kursi.description!), findsNothing);
      // The lead-in is a dhikr itself: it stays Arabic.
      expect(find.text(kursi.subtitle!), findsOneWidget);
    });

    testWidgets(
      'turns that phrase into its pronunciation with the Arabic off',
      (tester) async {
        await pump(tester, item: kursi, arabic: false);

        expect(find.text(kursi.subtitle!), findsNothing);
        expect(
          find.text("A'udhu billahi minash-shaytanir-rajim"),
          findsOneWidget,
        );
        expect(find.text(kursi.text), findsNothing);
      },
    );

    testWidgets('is in Arabic in Arabic', (tester) async {
      await pump(tester, item: kursi, inEnglish: false);

      expect(find.text('[${kursi.reference}]'), findsOneWidget);
      expect(find.text(kursi.description!), findsOneWidget);
      expect(find.text(english.reference!), findsNothing);
    });

    testWidgets('translates the lead-in of a dua too', (tester) async {
      final dua = dhikrLibrary.firstWhere((i) => i.subtitle == 'دعاء السفر');
      await pump(tester, item: dua);

      expect(find.text(dhikrEnglishData[dua.id]!.subtitle!), findsOneWidget);
      expect(find.text(dua.subtitle!), findsNothing);
    });

    testWidgets('puts the English of an explanation under its Arabic', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final item = libraryItemById('d884987d3e2')!;
      await pump(tester, item: item);

      expect(find.text(item.text), findsOneWidget);
      expect(find.text(dhikrEnglishData[item.id]!.text!), findsOneWidget);

      // With the Arabic off, only the English is left.
      await pump(tester, item: item, arabic: false);
      expect(find.text(item.text), findsNothing);
      expect(find.text(dhikrEnglishData[item.id]!.text!), findsOneWidget);
    });
  });

  group('the library settings popup', () {
    Future<ProviderContainer> open(
      WidgetTester tester, {
      bool english = true,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      if (english) {
        await tester.runAsync(
          () => container.read(localeProvider.notifier).toggle(),
        );
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const DhikrQuickSettingsPopup(), lang: 'en'),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('has only a switch for the Arabic, in English', (tester) async {
      final container = await open(tester);

      // There is no switch for the transliteration: English always has it.
      expect(
        find.byKey(const ValueKey('transliteration-switch')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('library-arabic-switch')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('library-arabic-switch')));
      await tester.pumpAndSettle();
      expect(container.read(dhikrLibraryProvider).showArabic, isFalse);
      // It is the Arabic that went; the transliteration stays on.
      expect(container.read(showTransliterationProvider), isTrue);
    });

    testWidgets('has no Arabic switch in Arabic: nothing to read instead', (
      tester,
    ) async {
      await open(tester, english: false);

      expect(find.byKey(const ValueKey('library-arabic-switch')), findsNothing);
      expect(
        find.byKey(const ValueKey('transliteration-switch')),
        findsNothing,
      );
    });
  });

  group('the notifications page', () {
    Future<ProviderContainer> open(
      WidgetTester tester, {
      bool english = true,
    }) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      if (english) {
        await tester.runAsync(
          () => container.read(localeProvider.notifier).toggle(),
        );
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const NotificationsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('collapsible-header')));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('has the same Arabic switch, for the reminder, in English', (
      tester,
    ) async {
      final container = await open(tester);

      await tester.tap(find.byKey(const ValueKey('overlay-arabic-switch')));
      await tester.pumpAndSettle();
      expect(container.read(dhikrSettingsProvider).overlayShowArabic, isFalse);
      // The library's own Arabic switch is a different one.
      expect(container.read(dhikrLibraryProvider).showArabic, isTrue);
    });

    testWidgets('has no such switch in Arabic', (tester) async {
      await open(tester, english: false);

      expect(find.byKey(const ValueKey('overlay-arabic-row')), findsNothing);
    });

    testWidgets('shows the transliteration under the dhikr in the list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final entry = _linked(_tasbeehId);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(
        () => container.read(dhikrSettingsProvider.notifier).updateEntries([
          entry,
        ]),
      );

      await tester.runAsync(
        () => container.read(localeProvider.notifier).toggle(),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const NotificationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final latin = entry.transliteration!.replaceAll('\n', ' ');
      final tile = find.byKey(ValueKey('tile-transliteration-${entry.id}'));
      expect(tile, findsOneWidget);
      expect(tester.widget<Text>(tile).data, latin);
      // Under the Arabic.
      expect(
        tester.getTopLeft(tile).dy,
        greaterThan(tester.getBottomLeft(find.text(entry.name)).dy - 1),
      );

      // And not in Arabic, which has no transliteration.
      await tester.runAsync(
        () => container.read(localeProvider.notifier).toggle(),
      );
      await tester.pumpAndSettle();
      expect(tile, findsNothing);
    });
  });

  group('the reminder card', () {
    Future<void> pump(
      WidgetTester tester, {
      required DhikrEntry entry,
      int count = 0,
      bool translit = true,
      bool arabic = true,
    }) async {
      tester.view.physicalSize = const Size(1120, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          DhikrReminderSurface(
            reminder: ActiveDhikrReminder(entry: entry, count: count),
            showTransliteration: translit,
            showArabic: arabic,
            onTap: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('shows the Arabic with the transliteration under it', (
      tester,
    ) async {
      final entry = _linked(_tasbeehId);
      await pump(tester, entry: entry);

      expect(find.text(entry.name), findsOneWidget);
      expect(find.text(entry.transliteration!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with the Arabic off shows the transliteration alone', (
      tester,
    ) async {
      final entry = _linked(_tasbeehId);
      await pump(tester, entry: entry, arabic: false);

      expect(find.text(entry.name), findsNothing);
      expect(find.text(entry.transliteration!), findsOneWidget);
    });

    testWidgets('without a transliteration it is the Arabic, switches or not', (
      tester,
    ) async {
      const entry = DhikrEntry(id: 4, name: 'سبحان الله', amount: 3);
      await pump(tester, entry: entry, arabic: false);

      expect(find.text(entry.name), findsOneWidget);
    });

    testWidgets('fits the longest reminders with a transliteration', (
      tester,
    ) async {
      // 500 characters of Arabic and the Latin that goes with it, in the
      // smallest room the card is ever given.
      final longest = dhikrLibrary
          .where(
            (item) =>
                item.isRemindable && dhikrTransliterations[item.id] != null,
          )
          .reduce((a, b) => a.text.length >= b.text.length ? a : b);
      await pump(tester, entry: _linked(longest.id));
      expect(tester.takeException(), isNull);
      expect(find.text(dhikrTransliterations[longest.id]!), findsOneWidget);
    });

    Future<void> pumpWithButton(
      WidgetTester tester, {
      required DhikrEntry entry,
      bool arabic = true,
      VoidCallback? onToggle,
    }) async {
      tester.view.physicalSize = const Size(1120, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Mounted the way the app mounts it: in MaterialApp.builder, above the
      // Navigator, so there is no Overlay around it (a Tooltip would throw).
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SizedBox.shrink(),
          builder: (context, _) => DhikrReminderSurface(
            reminder: ActiveDhikrReminder(entry: entry, count: 0),
            showTransliteration: true,
            showArabic: arabic,
            onToggleArabic: onToggle,
            onTap: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('has a button that turns the Arabic off and on', (
      tester,
    ) async {
      var presses = 0;
      await pumpWithButton(
        tester,
        entry: _linked(_tasbeehId),
        onToggle: () => presses++,
      );

      const button = ValueKey('reminder-arabic-button');
      expect(find.byKey(button), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is DhikrArabicToggleButton && w.tooltip == 'Hide the Arabic',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(button));
      expect(presses, 1);

      await pumpWithButton(
        tester,
        entry: _linked(_tasbeehId),
        arabic: false,
        onToggle: () => presses++,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is DhikrArabicToggleButton && w.tooltip == 'Show the Arabic',
        ),
        findsOneWidget,
      );
    });

    testWidgets('has no button where there is nothing to read instead', (
      tester,
    ) async {
      // A dhikr typed in by hand has no transliteration.
      await pumpWithButton(
        tester,
        entry: const DhikrEntry(id: 4, name: 'سبحان الله', amount: 3),
        onToggle: () {},
      );
      const button = ValueKey('reminder-arabic-button');
      expect(find.byKey(button), findsNothing);

      // And without a callback (the Arabic app) it is not offered at all.
      await pumpWithButton(tester, entry: _linked(_tasbeehId));
      expect(find.byKey(button), findsNothing);
    });

    testWidgets('the background breathes on a tap and comes back', (
      tester,
    ) async {
      final entry = _linked(_tasbeehId);
      await pump(tester, entry: entry);
      double lowest() => tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .reduce(min);
      final resting = lowest();

      tester.view.physicalSize = const Size(1120, 700);
      await tester.pumpWidget(
        _app(
          DhikrReminderSurface(
            reminder: ActiveDhikrReminder(entry: entry, count: 1),
            showTransliteration: true,
            onTap: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 210));
      // A little more see-through, not a flash.
      expect(lowest(), lessThan(resting - 0.1));
      expect(lowest(), greaterThan(resting - 0.3));

      await tester.pump(const Duration(milliseconds: 1000));
      expect(lowest(), closeTo(resting, 0.001));
    });
  });

  group('fitDhikrStackFontSize', () {
    const style = TextStyle(fontFamily: 'Ahem', height: 1.4);
    const box = Size(800, 300);

    double single(String text) => fitDhikrFontSize(
          text: text,
          style: style,
          box: box,
          textDirection: TextDirection.ltr,
          minFillRatio: 1,
        );

    test('leaves room for the transliteration under the Arabic', () {
      const text = 'one two three four five six seven eight nine ten';
      final stacked = fitDhikrStackFontSize(
        blocks: const [
          DhikrTextBlock(text: text, style: style),
          DhikrTextBlock(text: text, style: style, scale: 0.5, minFontSize: 8),
        ],
        box: box,
        gap: 10,
        textDirection: TextDirection.ltr,
        minFillRatio: 1,
      );

      expect(stacked, lessThan(single(text)));
      // And what it picked really fits.
      var height = 10.0;
      for (final scale in [1.0, 0.5]) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: style.copyWith(fontSize: stacked * scale),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
        )..layout(maxWidth: box.width);
        height += painter.height;
      }
      expect(height, lessThanOrEqualTo(box.height));
    });

    test('a block with no text takes no room', () {
      const text = 'one two three four five six seven eight nine ten';
      final stacked = fitDhikrStackFontSize(
        blocks: const [
          DhikrTextBlock(text: text, style: style),
          DhikrTextBlock(text: '', style: style, scale: 0.5),
        ],
        box: box,
        gap: 10,
        textDirection: TextDirection.ltr,
        minFillRatio: 1,
      );
      expect(stacked, closeTo(single(text), 0.01));
    });
  });
}
