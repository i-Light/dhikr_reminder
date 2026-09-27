import 'package:dhikr_reminder/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Semantic status colors with no slot in Material 3's [ColorScheme]
/// (success/warning/info — [ColorScheme.error] already covers the fourth).
///
/// Modeled as a [ThemeExtension] rather than a plain static class so each
/// tone can differ between [AppTheme.light] and [AppTheme.dark] later, and
/// so `ThemeData.lerp` (an animated theme switch) interpolates them
/// correctly — the pattern the Flutter team recommends for design tokens
/// that live outside the built-in [ColorScheme].
///
/// Fetch it via `Theme.of(context).extension<GratovoStatusColors>()!`
/// rather than importing [AppColors] directly in feature code. The main
/// planned consumer is the Deal-stage status pill (Won/Lost/Pending)
/// built in Phase 3.
@immutable
class GratovoStatusColors extends ThemeExtension<GratovoStatusColors> {
  const GratovoStatusColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color info;

  /// The one set of tones both themes use today. Split into separate
  /// light/dark instances if a future contrast pass finds these don't read
  /// well against both surfaces.
  static const standard = GratovoStatusColors(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
  );

  @override
  GratovoStatusColors copyWith({Color? success, Color? warning, Color? info}) {
    return GratovoStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  GratovoStatusColors lerp(
    ThemeExtension<GratovoStatusColors>? other,
    double t,
  ) {
    if (other is! GratovoStatusColors) return this;
    return GratovoStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// The brand gradients, as a [ThemeExtension] so they animate correctly
/// across a light/dark switch (`ThemeData.lerp` interpolates each stop) and
/// so a future light/dark split is a one-line change here rather than a hunt
/// through feature code.
///
/// The rule is a two-tier one:
///
/// * [brand] — **two** stops, blue → magenta — is the default for ordinary
///   gradient use: screen/section headings, app bars, panels, chips.
/// * [hero] — **three** stops, sky blue → magenta → rose — is reserved for
///   the one or two things that matter most on a screen: the primary call to
///   action, a screen's hero header, a headline figure. The rose third stop
///   is what tells "important" apart from "normal" at a glance.
///
/// [accent] (rose → magenta) is a warm-led alternative when a gradient should
/// read as secondary rather than primary. [wash] turns any of them
/// translucent, for laying a brand tint *over* a surface color (app bars,
/// cards) without hiding what is beneath.
///
/// Fetch via `GratovoGradients.of(context)`.
@immutable
class GratovoGradients extends ThemeExtension<GratovoGradients> {
  const GratovoGradients({
    required this.brand,
    required this.hero,
    required this.accent,
    required this.heading,
  });

  /// Two stops, blue → magenta. The default gradient.
  final LinearGradient brand;

  /// Three stops, sky blue → magenta → rose. Important things only.
  final LinearGradient hero;

  /// Two stops, rose → magenta. A warm-led alternative to [brand].
  final LinearGradient accent;

  /// For gradient TEXT only — a luminous bright-sky → rose ramp, both stops
  /// well above body-text luminance so a headline set in it reads as *more*
  /// prominent than the copy around it, not less. [brand] is mid-toned (it
  /// has to carry white button labels), which left gradient headings looking
  /// dim on the navy surface.
  final LinearGradient heading;

  static const _brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.tertiary],
  );

  static const _heading = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF45C4FF), Color(0xFFFF77A6)],
  );

  static const _hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    // The logo's own sweep: sky blue → magenta → rose.
    colors: [
      AppColors.primaryLight,
      AppColors.tertiary,
      AppColors.secondary,
    ],
  );

  static const _accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.tertiary],
  );

  /// Both themes share these today — the saturated brand hues read well on
  /// the navy dark surface and the near-white light background alike. Split
  /// into per-brightness instances if a contrast pass later disagrees.
  static const standard = GratovoGradients(
    brand: _brand,
    hero: _hero,
    accent: _accent,
    heading: _heading,
  );

  static GratovoGradients of(BuildContext context) =>
      Theme.of(context).extension<GratovoGradients>() ?? standard;

  /// A translucent copy of [gradient]: alpha ramps from [from] on the first
  /// stop to [to] on the last, so a brand tint can sit over an existing
  /// surface without covering it. Used by [GradientAppBar] and the washed
  /// mode of [GradientPanel].
  static LinearGradient wash(
    LinearGradient gradient, {
    double from = 0.22,
    double to = 0.06,
  }) {
    final colors = gradient.colors;
    final lastIndex = colors.length - 1;
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      stops: gradient.stops,
      colors: [
        for (var i = 0; i < colors.length; i++)
          colors[i].withValues(
            alpha: from + (to - from) * (lastIndex == 0 ? 0 : i / lastIndex),
          ),
      ],
    );
  }

  @override
  GratovoGradients copyWith({
    LinearGradient? brand,
    LinearGradient? hero,
    LinearGradient? accent,
    LinearGradient? heading,
  }) {
    return GratovoGradients(
      brand: brand ?? this.brand,
      hero: hero ?? this.hero,
      accent: accent ?? this.accent,
      heading: heading ?? this.heading,
    );
  }

  @override
  GratovoGradients lerp(ThemeExtension<GratovoGradients>? other, double t) {
    if (other is! GratovoGradients) return this;
    return GratovoGradients(
      brand: LinearGradient.lerp(brand, other.brand, t)!,
      hero: LinearGradient.lerp(hero, other.hero, t)!,
      accent: LinearGradient.lerp(accent, other.accent, t)!,
      heading: LinearGradient.lerp(heading, other.heading, t)!,
    );
  }
}

/// The two "spark" accents — a lemon-lime and a periwinkle — modelled as a
/// [ThemeExtension] for the same reasons as [GratovoGradients]: a light/dark
/// split later is a one-line change here, and `ThemeData.lerp` interpolates
/// them across an animated theme switch.
///
/// These are the counter-move to a screen full of blue and magenta cards.
/// Used *sparingly* — an icon, a 3px edge strip, a chip — never a surface
/// fill. Fetch via `GratovoAccents.of(context)`.
@immutable
class GratovoAccents extends ThemeExtension<GratovoAccents> {
  const GratovoAccents({required this.citron, required this.iris});

  /// Lemon-lime. Complements the blue primary; reads loudest of the two.
  final Color citron;

  /// Periwinkle, sitting between the logo's blue and its pink.
  final Color iris;

  static const standard = GratovoAccents(
    citron: AppColors.sparkCitron,
    iris: AppColors.sparkIris,
  );

  static GratovoAccents of(BuildContext context) =>
      Theme.of(context).extension<GratovoAccents>() ?? standard;

  @override
  GratovoAccents copyWith({Color? citron, Color? iris}) => GratovoAccents(
        citron: citron ?? this.citron,
        iris: iris ?? this.iris,
      );

  @override
  GratovoAccents lerp(ThemeExtension<GratovoAccents>? other, double t) {
    if (other is! GratovoAccents) return this;
    return GratovoAccents(
      citron: Color.lerp(citron, other.citron, t)!,
      iris: Color.lerp(iris, other.iris, t)!,
    );
  }
}

/// The app's light and dark themes.
///
/// Only [dark] actually ships in the UI today (the theme toggle in Settings
/// is Phase 4 work), but both are built from the start so "add a light
/// theme later" never means "go find every hardcoded color in every widget"
/// — it means "flip `themeModeProvider`". Every color/shape/text-style
/// decision lives here, in one place, rather than inline in feature code.
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Cairo';

  static ThemeData get dark => _themeFrom(
        brightness: Brightness.dark,
        scaffoldBackground: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        card: AppColors.darkCard,
        cardBright: AppColors.darkCardBright,
        border: AppColors.darkBorder,
      );

  static ThemeData get light => _themeFrom(
        brightness: Brightness.light,
        scaffoldBackground: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        card: AppColors.lightCard,
        cardBright: AppColors.lightCard,
        border: AppColors.lightBorder,
      );

  static ThemeData _themeFrom({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surface,
    required Color card,
    required Color cardBright,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;

    // ColorScheme.fromSeed derives a complete, harmonious, accessible
    // Material 3 tonal palette (containers, tertiary, outline, surface
    // variants, ...) from a single seed, rather than hand-picking every
    // slot — see theme_patterns.md in the flutter-dev skill.
    // `fromSeed` only takes one seed color (there's no secondary-seeding
    // parameter in the stable API, despite some third-party forks adding
    // one), so the brand's rose secondary and magenta tertiary are pinned
    // afterwards via `copyWith` — along with their `on*` pair colors, since
    // a generic algorithm can't be trusted to pick readable text over an
    // arbitrary override color: black clears 6:1 on the rose, white is the
    // conventional pairing on the magenta. Plus the custom blue-navy surface
    // tone and the loud brand error red.
    //
    // The second block repoints fromSeed's *neutral* family — the
    // surface-container ramp, the `*Variant` tones, the muted-label color.
    // fromSeed derives those at near-zero chroma, so over the blue-navy
    // scaffold they land as flat grey patches that read as "unstyled".
    // Retinting them blue keeps every card inset, divider and caption
    // on-palette without touching feature code. The ramp is spread wide
    // (lowest well below the scaffold, highest well above the card) so
    // surfaces stack with real depth instead of one flat field.
    //
    // The third block keeps the container pairs (`secondaryContainer`,
    // `tertiaryContainer`) on a toned blue / restrained magenta. An earlier
    // pass pinned `secondaryContainer` to the full brand ROSE to "break the
    // monochrome" — but every selected chip, segment, tonal button and
    // date-picker selection routes through that one role, so it put pink on
    // every screen. Brand color belongs in accents, not behind every
    // selected control.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      surface: surface,
      error: AppColors.error,
      // Neutral family — blue-tinted (dark) / faint-blue (light), so insets
      // and dividers stay on the logo's hue instead of drifting grey.
      surfaceContainerLowest:
          isDark ? const Color(0xFF040F17) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          isDark ? const Color(0xFF0B2030) : const Color(0xFFF3F8FD),
      surfaceContainer:
          isDark ? const Color(0xFF122A3D) : const Color(0xFFEDF3FA),
      surfaceContainerHigh:
          isDark ? const Color(0xFF1A374E) : const Color(0xFFE4EDF6),
      surfaceContainerHighest:
          isDark ? const Color(0xFF224460) : const Color(0xFFDAE6F1),
      onSurfaceVariant:
          isDark ? const Color(0xFFAEC2D6) : AppColors.mutedForeground,
      outline: isDark ? const Color(0xFF5E7C96) : const Color(0xFF93A7BA),
      outlineVariant: isDark ? AppColors.darkBorder : const Color(0xFFD3E0EC),
      // Selected chips, segmented buttons, tonal buttons and date-picker
      // selections all route through `secondaryContainer`. Pinning that to
      // the brand rose put pink on every selected control on every screen —
      // too much. It's a toned blue container now; rose stays a true accent
      // (the `secondary` role, the odd spark edge), not a background.
      secondaryContainer:
          isDark ? const Color(0xFF13415E) : const Color(0xFFCFE6F7),
      onSecondaryContainer:
          isDark ? const Color(0xFFCDE7F8) : const Color(0xFF0A3854),
      // A restrained magenta for the tertiary container pair — this role is
      // used far more sparingly, so a little brand color here is fine.
      tertiaryContainer:
          isDark ? const Color(0xFF3E2A3B) : const Color(0xFFF3E1EE),
      onTertiaryContainer:
          isDark ? const Color(0xFFEAD3E3) : const Color(0xFF3B1832),
    );

    final onSurface = colorScheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      extensions: const [
        GratovoStatusColors.standard,
        GratovoGradients.standard,
        GratovoAccents.standard,
      ],
      cardTheme: CardThemeData(
        color: card,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onSurface,
          fontFamily: _fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // colorScheme.primary, not the raw brand indigo: `fromSeed` tones
          // it per brightness so it stays legible on both the navy dark
          // scaffold and the near-white light one.
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontFamily: _fontFamily,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontFamily: _fontFamily,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
