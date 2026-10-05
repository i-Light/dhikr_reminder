import 'dart:math' as math;
import 'dart:ui';

/// Gap between a popup and the tray icon it opened from, and between a popup
/// and the screen's edge, in logical pixels.
const kWindowGap = 10.0;

/// A [size] window in the middle of [area], shrunk to fit inside it with
/// [gap] to spare on every side.
Rect centredRect(Rect area, Size size, {double gap = kWindowGap}) {
  final fitted = Size(
    math.min(size.width, area.width - gap * 2),
    math.min(size.height, area.height - gap * 2),
  );
  return Rect.fromCenter(
    center: area.center,
    width: fitted.width,
    height: fitted.height,
  );
}

/// Where a popup of [size] goes when opened from the tray icon under
/// [cursor]: centred on the cursor, above it when the icon is in the lower
/// half of [area] and below it otherwise, and always fully inside [area].
Rect popupRectNearCursor(
  Offset cursor,
  Rect area,
  Size size, {
  double gap = kWindowGap,
}) {
  final above = cursor.dy > area.center.dy;
  final left = (cursor.dx - size.width / 2)
      .clamp(
        area.left + gap,
        math.max(area.left + gap, area.right - size.width - gap),
      )
      .toDouble();
  final top = (above ? cursor.dy - size.height - gap : cursor.dy + gap)
      .clamp(
        area.top + gap,
        math.max(area.top + gap, area.bottom - size.height - gap),
      )
      .toDouble();
  return Rect.fromLTWH(left, top, size.width, size.height);
}
