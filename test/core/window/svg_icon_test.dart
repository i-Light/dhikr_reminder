import 'package:dhikr_reminder/core/window/svg_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inlineUsedImages', () {
    test('replaces a <use> of an <image> with the image, in place', () {
      const svg = '<svg><g><use xlink:href="#a" x="10" y="20" '
          'width="30px" height="40px"/></g>'
          '<defs><image id="a" width="1px" height="2px" '
          'xlink:href="data:image/png;base64,AAAA"/></defs></svg>';

      final out = inlineUsedImages(svg);

      expect(out, contains('<g><image'));
      expect(out, contains('xlink:href="data:image/png;base64,AAAA"'));
      expect(out, contains('x="10"'));
      expect(out, contains('width="30"'));
      expect(out, isNot(contains('<use')));
    });

    test('leaves a <use> of anything else alone', () {
      const svg = '<svg><use xlink:href="#p"/><defs><path id="p"/></defs></svg>';
      expect(inlineUsedImages(svg), svg);
    });
  });
}
