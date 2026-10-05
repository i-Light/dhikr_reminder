import 'package:dhikr_reminder/core/window/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// The app's logo, drawn from the same SVG as the tray icon and the splash.
///
/// The SVG is read once and kept, so a logo that appears again (every reminder
/// card, say) is there on its first frame.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  static final Future<String> _svg =
      rootBundle.loadString(kAppIconSvgAsset).then(inlineUsedImages);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<String>(
        future: _svg,
        builder: (context, snapshot) => snapshot.hasData
            ? SvgPicture.string(snapshot.data!)
            : const SizedBox.shrink(),
      ),
    );
  }
}
