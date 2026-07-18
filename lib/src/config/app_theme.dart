import 'dart:io';
import 'package:flutter/material.dart';

class AppTheme {
  // Dark Theme Colors
  static const Color darkScaffoldBg = Color(0xFF0F1014);
  static const Color darkCardColor = Color(0xFF1E1F24);
  static const Color darkPrimaryColor = Color(0xFFE50914);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFFB3B3B3);

  // Light Theme Colors
  static const Color lightScaffoldBg = Colors.transparent;
  static const Color lightCardColor = Color(0xFFB3B3B3);
  static const Color lightPrimaryColor = Color(0xFFE50914);
  static const Color lightOnSurface = Color(0xFF2C2C2E);
  static const Color lightOnSurfaceVariant = Color(0xFF48484A);

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
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: Colors.red,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
        thumbColor: Colors.red,
        overlayColor: Colors.red.withValues(alpha: 0.2),
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
        onSurfaceVariant: darkOnSurfaceVariant,
        surfaceContainerLow: const Color(0xFF16171C),
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(25), width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardColor,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
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
        onSurfaceVariant: lightOnSurfaceVariant,
        surfaceContainerLow: Colors.transparent,
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withAlpha(20), width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
