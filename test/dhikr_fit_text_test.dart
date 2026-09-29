import 'package:dhikr_reminder/core/toast/dhikr_fit_text.dart';
import 'package:dhikr_reminder/core/window/tray_menu_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _style = TextStyle(fontFamily: 'Ahem', height: 1.6, wordSpacing: 12);
const _box = Size(800, 300);

double _fit(String text, {Size box = _box, double minFill = 1.0}) =>
    fitDhikrFontSize(
      text: text,
      style: _style,
      box: box,
      textDirection: TextDirection.rtl,
      minFillRatio: minFill,
    );

/// Lays [text] out at [fontSize] the same way the fitter does.
Size _measure(String text, double fontSize, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: _style.copyWith(fontSize: fontSize)),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: maxWidth);
  return painter.size;
}

void main() {
  group('fitDhikrFontSize', () {
    test('the size it returns fits the box', () {
      const text = 'سبحان الله وبحمده سبحان الله العظيم';
      final size = _fit(text);
      final measured = _measure(text, size, _box.width);

      expect(measured.height, lessThanOrEqualTo(_box.height));
      expect(measured.width, lessThanOrEqualTo(_box.width));
    });

    test('is as big as it can be: a little more would no longer fit', () {
      const text = 'سبحان الله وبحمده سبحان الله العظيم';
      final size = _fit(text);
      final bigger = _measure(text, size + 2, _box.width);

      expect(
        bigger.height > _box.height || bigger.width > _box.width,
        isTrue,
      );
    });

    test('longer text gets a smaller size', () {
      final short = _fit('a b c d e f g h i j');
      final long = _fit(List.filled(40, 'word').join(' '));

      expect(long, lessThan(short));
    });

    test('a bigger box gets a bigger size', () {
      const text = 'one two three four five six seven eight nine ten';

      expect(_fit(text, box: const Size(1200, 500)),
          greaterThan(_fit(text, box: const Size(600, 200))));
    });

    test('never breaks a single word across lines', () {
      const text = 'supercalifragilisticexpialidocious';
      final size = _fit(text, box: const Size(300, 600));

      expect(_measure(text, size, 300).width, lessThanOrEqualTo(300));
    });

    test('a degenerate box or empty text yields the floor, not a crash', () {
      expect(_fit('text', box: Size.zero), greaterThan(0));
      expect(_fit('   '), greaterThan(0));
    });
  });

  group('dhikrFillRatio', () {
    test('a single word gets only the minimum ratio', () {
      expect(dhikrFillRatio(1, minFillRatio: 0.5, fullFillWords: 10), 0.5);
    });

    test('climbs to a full fill at the full-fill word count and stays there',
        () {
      expect(dhikrFillRatio(10, minFillRatio: 0.5, fullFillWords: 10), 1);
      expect(dhikrFillRatio(50, minFillRatio: 0.5, fullFillWords: 10), 1);
      expect(
        dhikrFillRatio(5, minFillRatio: 0.5, fullFillWords: 10),
        allOf(greaterThan(0.5), lessThan(1)),
      );
    });

    test('a short dhikr ends up smaller than a full fill of the same box', () {
      final full = _fit('one two', minFill: 1.0);
      final capped = fitDhikrFontSize(
        text: 'one two',
        style: _style,
        box: _box,
        textDirection: TextDirection.rtl,
        minFillRatio: 0.5,
      );

      expect(capped, lessThan(full));
    });
  });

  group('formatCountdown', () {
    test('formats minutes and seconds under an hour', () {
      expect(formatCountdown(const Duration(minutes: 5, seconds: 7)), '5:07');
    });

    test('adds hours from an hour up', () {
      expect(
        formatCountdown(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('never goes negative', () {
      expect(formatCountdown(const Duration(seconds: -4)), '0:00');
    });
  });
}
