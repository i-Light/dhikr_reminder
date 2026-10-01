// Draws the .exe's icon (windows/runner/resources/app_icon.ico) from the app's
// one icon, assets/images/logo.svg.
//
// Run by scripts/build_windows.ps1 before every build:
//
//     flutter test tool/generate_app_icon.dart
//
// It is a "test" only because rendering an SVG needs Flutter's own painting
// engine, and `flutter test` is the way to run Dart code with it outside an
// app. The generated .ico is git-ignored: the SVG is the one source.
import 'dart:io';

import 'package:dhikr_reminder/core/window/svg_icon.dart';
import 'package:flutter_test/flutter_test.dart';

const _output = 'windows/runner/resources/app_icon.ico';

void main() {
  testWidgets('generate the Windows app icon from the SVG', (tester) async {
    await tester.runAsync(() async {
      final svg = await File(kAppIconSvgAsset).readAsString();
      final ico = await renderSvgAsIco(svg);
      await File(_output).writeAsBytes(ico, flush: true);
    });
    expect(File(_output).existsSync(), isTrue);
  });
}
