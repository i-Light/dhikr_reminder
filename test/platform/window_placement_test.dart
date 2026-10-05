import 'dart:ui';

import 'package:dhikr_reminder/platform/windows/window_placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const area = Rect.fromLTWH(0, 0, 1920, 1040);

  group('centredRect', () {
    test('puts a window that fits in the middle of the area', () {
      final rect = centredRect(area, const Size(1120, 700));

      expect(rect.size, const Size(1120, 700));
      expect(rect.center, area.center);
    });

    test('shrinks a window that is too big to leave the gap on every side', () {
      final rect = centredRect(area, const Size(5000, 5000));

      expect(rect.width, area.width - 2 * kWindowGap);
      expect(rect.height, area.height - 2 * kWindowGap);
      expect(rect.center, area.center);
    });

    test('works on a monitor that does not start at the origin', () {
      const second = Rect.fromLTWH(-1920, 0, 1920, 1040);

      expect(centredRect(second, const Size(420, 270)).center, second.center);
    });
  });

  group('popupRectNearCursor', () {
    const size = Size(208, 212);

    test('opens above the cursor when the tray is in the lower half', () {
      final rect = popupRectNearCursor(const Offset(1800, 1030), area, size);

      expect(rect.bottom, 1030 - kWindowGap);
    });

    test('opens below the cursor when the tray is in the upper half', () {
      final rect = popupRectNearCursor(const Offset(960, 5), area, size);

      expect(rect.top, 5 + kWindowGap);
    });

    test('is centred on the cursor when there is room', () {
      final rect = popupRectNearCursor(const Offset(960, 1030), area, size);

      expect(rect.center.dx, 960);
    });

    test('never leaves the area, however near the edge the cursor is', () {
      for (final cursor in const [
        Offset(0, 0),
        Offset(1920, 0),
        Offset(0, 1040),
        Offset(1920, 1040),
      ]) {
        final rect = popupRectNearCursor(cursor, area, size);
        expect(rect.left, greaterThanOrEqualTo(area.left + kWindowGap));
        expect(rect.right, lessThanOrEqualTo(area.right - kWindowGap));
        expect(rect.top, greaterThanOrEqualTo(area.top + kWindowGap));
        expect(rect.bottom, lessThanOrEqualTo(area.bottom - kWindowGap));
      }
    });

    test('does not throw when the area is smaller than the popup', () {
      const tiny = Rect.fromLTWH(0, 0, 100, 100);

      expect(
        () => popupRectNearCursor(const Offset(50, 50), tiny, size),
        returnsNormally,
      );
    });
  });
}
