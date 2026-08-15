import 'dart:io';
import 'package:flutter/material.dart';

class AppTheme {
  // ── Accents ───────────────────────────────────────────────────────────────
  // Three saturated colours in the whole app, each with exactly one meaning.
  // The palette this replaced spent a Netflix red on every selected thing, an
  // orange on both "new" and the rating, a blue on the language tag and a cyan
  // on progress — five colours saying nothing in particular, so nothing on a
  // card stood out from anything else.

  /// Selection and focus. Cyan rather than the old red because it is also the
  /// playback-progress colour: "where you are" is one idea, and a selected
  /// source feeding a grid is the same kind of statement as a progress bar.
  ///
  /// These three are [VidraTokens]' `cyan` / `amber` / `clash`; the constants
  /// stay because a `ColorScheme` needs literals. Widgets should read the
  /// tokens, which carry the light variant too.
  static const Color accent = Color(0xFF7BE7F0);
  static const Color accentLight = Color(0xFF0C7C87);

  /// Reserved for ONE thing: this gained an episode. Nothing else may use it,
  /// which is what makes an amber dot worth looking at.
  static const Color onAir = Color(0xFFFFC559);

  /// Reserved for source disagreement.
  static const Color clash = Color(0xFFFF9A7A);

  // ── Dark ──────────────────────────────────────────────────────────────────
  // Neutrals biased toward the accent instead of pure grey: a card on a warm
  // grey over a teal-lit background reads as a different material, and every
  // surface in a glass-and-ambient design has to look like it belongs to the
  // same room.

  /// The base the ambient light is painted over — see [AmbientBackground],
  /// which paints the real page ramp on top of it. This is what shows through
  /// where a widget asks the theme for a background instead: the pinned
  /// episode bar's opaque state, a dialog, a snack bar.
  static const Color darkScaffoldBg = Color(0xFF0A1220);

  /// Translucent, not solid: surfaces are meant to let the ambient wash show
  /// through. A solid card over a lit background is the one thing that reads as
  /// pasted on. `--glass-2`, top stop.
  static const Color darkCardColor = Color(0x13FFFFFF);
  static const Color darkPrimaryColor = accent;
  static const Color darkOnSurface = Color(0xF5FFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xA8FFFFFF);

  // ── Light ─────────────────────────────────────────────────────────────────
  static const Color lightScaffoldBg = Color(0xFFE7EDF5);
  static const Color lightCardColor = Color(0x9EFFFFFF);
  static const Color lightPrimaryColor = accentLight;
  static const Color lightOnSurface = Color(0xF20C141E);
  static const Color lightOnSurfaceVariant = Color(0x9E0C141E);

  // 字体名
  static const String windowsFont = "HarmonyOSSans";
  static const String windowsFontFallback = "HarmonyOSSans_SC";

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color primaryColor,
    required TextTheme baseTextTheme,
    required IconThemeData iconTheme,
    required AppBarTheme appBarTheme,
    required CardThemeData cardTheme,
    required DialogThemeData dialogTheme,
  }) {
    // Apply bundled fonts on platforms that lack system CJK support.
    // macOS has built-in CJK coverage; Windows and Linux do not.
    final bool useBundledFont = Platform.isWindows || Platform.isLinux;
    final String? fontFamily = useBundledFont ? windowsFont : null;
    final List<String> fontFamilyFallback = useBundledFont
        ? [windowsFontFallback]
        : [];

    // 应用字体到 TextTheme
    TextTheme applyFont(TextTheme t) => t.copyWith(
      displayLarge: t.displayLarge?.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
      bodyMedium: t.bodyMedium?.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
      bodySmall: t.bodySmall?.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
    );

    // 全局 DialogTheme 自动继承 TextTheme 的字体和颜色
    DialogThemeData applyDialog(DialogThemeData d, TextTheme t) {
      return d.copyWith(
        titleTextStyle:
            d.titleTextStyle?.copyWith(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFamilyFallback,
              color: d.titleTextStyle?.color ?? t.titleLarge?.color,
              fontSize: d.titleTextStyle?.fontSize ?? t.titleLarge?.fontSize,
            ) ??
            TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFamilyFallback,
              color: t.titleLarge?.color,
              fontSize: t.titleLarge?.fontSize ?? 20,
              fontWeight: FontWeight.bold,
            ),
        contentTextStyle:
            d.contentTextStyle?.copyWith(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFamilyFallback,
              color: d.contentTextStyle?.color ?? t.bodyMedium?.color,
              fontSize: d.contentTextStyle?.fontSize ?? t.bodyMedium?.fontSize,
            ) ??
            TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFamilyFallback,
              color: t.bodyMedium?.color,
              fontSize: t.bodyMedium?.fontSize ?? 16,
            ),
      );
    }

    final textTheme = applyFont(baseTextTheme);
    final appliedDialogTheme = applyDialog(dialogTheme, textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      textTheme: textTheme,
      iconTheme: iconTheme,
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      dialogTheme: appliedDialogTheme,
      // The one in the delete-task dialog was an unstyled white square with no
      // fill state to speak of.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(
          brightness == Brightness.dark
              ? const Color(0xFF05323A)
              : Colors.white,
        ),
        side: BorderSide(color: colorScheme.onSurfaceVariant, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Borrowed from the dialog, which is the one surface in this app whose
      // colours were chosen rather than derived.
      //
      // Left to Material this was WHITE TEXT ON A WHITE SURFACE in the dark
      // theme — `inverseSurface` and `onInverseSurface` are the only two roles
      // the ColorScheme above does not name, and what they derive to happens to
      // collide. Nothing failed and nothing looked broken: the snack bar
      // appeared, correctly sized, holding an invisible sentence. Every error
      // this app reports to a person arrives this way, so a cast that failed
      // for a nameable, actionable reason read as one that failed silently.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: appliedDialogTheme.backgroundColor,
        contentTextStyle: appliedDialogTheme.contentTextStyle,
        elevation: 12,
        shape: appliedDialogTheme.shape,
        actionTextColor: primaryColor,
      ),
      // primaryColor, not the dark accent literal: on the light theme a
      // #7BE7F0 track is a pale wash on near-white, and the inactive half was
      // white-on-white outright.
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: primaryColor,
        inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.16),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.18),
      ),
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkScaffoldBg,
      primaryColor: darkPrimaryColor,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkPrimaryColor,
        surface: darkCardColor,
        onSurface: darkOnSurface,
        outline: const Color(0x3DFFFFFF),
        onSurfaceVariant: darkOnSurfaceVariant,
        surfaceContainerLow: const Color(0x0DFFFFFF),
      ),
      baseTextTheme: ThemeData.dark().textTheme.copyWith(
        displayLarge: const TextStyle(
          color: darkOnSurface,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: const TextStyle(
          color: darkOnSurface,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: const TextStyle(color: darkOnSurfaceVariant),
        bodySmall: const TextStyle(color: darkOnSurfaceVariant),
      ),
      iconTheme: const IconThemeData(color: darkOnSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withAlpha(28), width: 0.5),
        ),
      ),
      dialogTheme: _dialogTheme(
        background: const Color(0xFF141F30),
        edge: const Color(0x29FFFFFF),
        title: darkOnSurface,
        body: darkOnSurfaceVariant,
      ),
    );
  }

  /// One dialog surface for both themes.
  ///
  /// They used to be a Material default with a hardcoded fill and no outline:
  /// a dark slab on a dark scrim over a dark page, with nothing marking where
  /// the panel ended. The border is what makes it a sheet of something rather
  /// than a hole, and it is the same `--edge` every other surface uses.
  static DialogThemeData _dialogTheme({
    required Color background,
    required Color edge,
    required Color title,
    required Color body,
  }) {
    return DialogThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 20,
      shadowColor: const Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: edge),
      ),
      titleTextStyle: TextStyle(
        color: title,
        fontSize: 17,
        height: 1.4,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      contentTextStyle: TextStyle(color: body, fontSize: 13.5, height: 1.6),
    );
  }

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightScaffoldBg,
      primaryColor: lightPrimaryColor,
      colorScheme: ColorScheme.light(
        primary: lightPrimaryColor,
        secondary: lightPrimaryColor,
        surface: lightCardColor,
        onSurface: lightOnSurface,
        outline: const Color(0x330C141E),
        onSurfaceVariant: lightOnSurfaceVariant,
        surfaceContainerLow: const Color(0x99FFFFFF),
      ),
      baseTextTheme: ThemeData.light().textTheme.copyWith(
        displayLarge: const TextStyle(
          color: lightOnSurface,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: const TextStyle(
          color: lightOnSurface,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: const TextStyle(color: lightOnSurface),
        bodySmall: const TextStyle(color: lightOnSurfaceVariant),
      ),
      iconTheme: const IconThemeData(color: lightOnSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withAlpha(18), width: 0.5),
        ),
      ),
      dialogTheme: _dialogTheme(
        background: const Color(0xFFF7FAFD),
        edge: const Color(0x1F0C141E),
        title: lightOnSurface,
        body: lightOnSurfaceVariant,
      ),
    );
  }
}
