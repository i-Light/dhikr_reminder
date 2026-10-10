import 'package:dhikr_reminder/core/toast/border_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  setUp(BakedSvg.clearCache);
  tearDown(BakedSvg.clearCache);

  testWidgets('is drawn live at first, then as one image', (tester) async {
    const svg = BakedSvg(
      asset: 'assets/images/frame_corner.svg',
      width: 120,
      height: 120,
      color: Color(0xFFE9C758),
    );
    await tester
        .pumpWidget(_app(const SizedBox(width: 120, height: 120, child: svg)));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);

    // The picture is taken once the first frame is on screen.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('a second one of the same kind starts as the image',
      (tester) async {
    const svg = BakedSvg(
      asset: 'assets/images/frame_corner.svg',
      width: 120,
      height: 120,
      color: Color(0xFFE9C758),
    );
    await tester
        .pumpWidget(_app(const SizedBox(width: 120, height: 120, child: svg)));
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }
    await tester.pumpWidget(const SizedBox.shrink());

    await tester
        .pumpWidget(_app(const SizedBox(width: 120, height: 120, child: svg)));
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });
}
