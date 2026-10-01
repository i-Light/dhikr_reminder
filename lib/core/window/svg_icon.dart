import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

/// Where the app's one icon lives. Everything else — the tray icon, the tray
/// icon while quitting, the .exe's own icon (see `tool/generate_app_icon.dart`)
/// — is drawn from this file, so replacing it is the whole job.
const kAppIconSvgAsset = 'assets/images/logo.svg';

/// The sizes packed into every generated .ico. Windows picks the nearest one
/// for the tray (16 px at 100% scaling, up to 32 px at 200%), the taskbar and
/// the file explorer.
const kAppIconSizes = [16, 20, 24, 32, 40, 48, 64, 128, 256];

/// Renders [svg] into a Windows .ico holding one image per size in [sizes].
///
/// [dimmed] draws the grayed-out, semi-transparent variant used while the app
/// is closing. The picture is fitted inside each square and centred, so a
/// non-square SVG is never stretched.
Future<Uint8List> renderSvgAsIco(
  String svg, {
  List<int> sizes = kAppIconSizes,
  bool dimmed = false,
}) async {
  final info = await vg.loadPicture(
    SvgStringLoader(inlineUsedImages(svg)),
    null,
  );
  try {
    final images = <Uint8List>[];
    for (final size in sizes) {
      images.add(await _renderPng(info, size, dimmed));
    }
    return _packIco(sizes, images);
  } finally {
    info.picture.dispose();
  }
}

/// Rewrites every `<use xlink:href="#id"/>` that points at an `<image id="id">`
/// into an `<image>` drawn in place.
///
/// Design tools (Affinity, for one) export raster parts of a logo — gradient
/// meshes, textures — as an `<image>` in `<defs>` shown through `<use>`.
/// flutter_svg silently skips such a `<use>`, so those parts vanish from the
/// icon. Inlining lets the SVG stay exactly as exported.
String inlineUsedImages(String svg) {
  final images = <String, String>{}; // id -> attributes other than the id
  final imageTag = RegExp(r'<image\b([^>]*?)/?>', dotAll: true);
  for (final match in imageTag.allMatches(svg)) {
    final attributes = match.group(1)!;
    final id = RegExp(r'\bid="([^"]*)"').firstMatch(attributes)?.group(1);
    if (id == null) continue;
    images[id] = attributes.replaceFirst(RegExp(r'\s*\bid="[^"]*"'), '');
  }
  if (images.isEmpty) return svg;

  return svg.replaceAllMapped(
    RegExp(r'<use\b([^>]*?)/?>', dotAll: true),
    (use) {
      final attributes = use.group(1)!;
      final ref = RegExp(r'''(?:xlink:)?href\s*=\s*["']#([^"']*)["']''')
          .firstMatch(attributes)
          ?.group(1);
      final found = images[ref];
      if (found == null) return use.group(0)!;
      var image = found;
      // The <use>'s own x/y/width/height win over the image's, as in SVG.
      String? own(String name) =>
          RegExp('\\b$name="([^"]*)"').firstMatch(attributes)?.group(1);
      final merged = StringBuffer();
      for (final name in const ['x', 'y', 'width', 'height']) {
        final value = own(name);
        if (value == null) continue;
        image = image.replaceAll(RegExp('\\s*\\b$name="[^"]*"'), '');
        merged.write(' $name="${value.replaceAll('px', '')}"');
      }
      return '<image$image$merged/>';
    },
  );
}

Future<Uint8List> _renderPng(PictureInfo info, int size, bool dimmed) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (dimmed) {
    // Luminance into every channel (grayscale), alpha down to 60%.
    canvas.saveLayer(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      ui.Paint()
        ..colorFilter = const ui.ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.6, 0,
        ]),
    );
  }
  final scale = size /
      (info.size.width > info.size.height ? info.size.width : info.size.height);
  canvas
    ..translate(
      (size - info.size.width * scale) / 2,
      (size - info.size.height * scale) / 2,
    )
    ..scale(scale)
    ..drawPicture(info.picture);
  if (dimmed) canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

/// An .ico is a small directory followed by the images; since Windows Vista
/// each image can simply be a PNG.
Uint8List _packIco(List<int> sizes, List<Uint8List> pngs) {
  final headerLength = 6 + 16 * pngs.length;
  final total =
      headerLength + pngs.fold<int>(0, (sum, png) => sum + png.length);
  final bytes = Uint8List(total);
  final view = ByteData.sublistView(bytes);
  view
    ..setUint16(0, 0, Endian.little) // reserved
    ..setUint16(2, 1, Endian.little) // type: icon
    ..setUint16(4, pngs.length, Endian.little);
  var offset = headerLength;
  for (var i = 0; i < pngs.length; i++) {
    final entry = 6 + 16 * i;
    final dimension = sizes[i] >= 256 ? 0 : sizes[i]; // 0 means 256
    view
      ..setUint8(entry, dimension)
      ..setUint8(entry + 1, dimension)
      ..setUint16(entry + 4, 1, Endian.little) // colour planes
      ..setUint16(entry + 6, 32, Endian.little) // bits per pixel
      ..setUint32(entry + 8, pngs[i].length, Endian.little)
      ..setUint32(entry + 12, offset, Endian.little);
    bytes.setRange(offset, offset + pngs[i].length, pngs[i]);
    offset += pngs[i].length;
  }
  return bytes;
}
