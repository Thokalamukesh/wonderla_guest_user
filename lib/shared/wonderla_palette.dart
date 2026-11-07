import 'package:flutter/material.dart';

/// Wonderla's visual identity is built around its bright yellow wordmark and
/// deep blue lettering. These colors keep that contrast while giving screens
/// a calmer, accessible canvas.
const wonderlaNavy = Color(0xff102454);
const wonderlaCobalt = Color(0xff1746A2);
const wonderlaBlue = Color(0xff2457D6);
const wonderlaGold = Color(0xffffd21f);
const wonderlaCream = Color(0xfff5f7fb);
const wonderlaWhite = Color(0xffffffff);
const wonderlaSurface = Color(0xffffffff);
const wonderlaBorder = Color(0xffe1e7f0);
const wonderlaMuted = Color(0xff64748b);
const wonderlaSuccess = Color(0xff16835d);
const wonderlaWarning = Color(0xffa65c00);
const wonderlaFlagRed = Color(0xffb4233c);

const wonderlaCardRadius = 20.0;

ThemeData buildWonderlaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: wonderlaCobalt,
    brightness: Brightness.light,
    primary: wonderlaCobalt,
    onPrimary: wonderlaWhite,
    secondary: wonderlaGold,
    onSecondary: wonderlaNavy,
    surface: wonderlaSurface,
    onSurface: wonderlaNavy,
    error: wonderlaFlagRed,
    onError: wonderlaWhite,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: wonderlaCream,
    canvasColor: wonderlaCream,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: wonderlaNavy,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        color: wonderlaNavy,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: wonderlaNavy,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: wonderlaNavy, fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(color: wonderlaMuted, fontSize: 14, height: 1.4),
    ),
    iconTheme: const IconThemeData(color: wonderlaCobalt),
    appBarTheme: const AppBarTheme(
      backgroundColor: wonderlaSurface,
      foregroundColor: wonderlaNavy,
      surfaceTintColor: wonderlaSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: wonderlaNavy,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: wonderlaSurface,
      surfaceTintColor: wonderlaSurface,
      elevation: 1,
      shadowColor: wonderlaNavy.withValues(alpha: .08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(wonderlaCardRadius),
        side: const BorderSide(color: wonderlaBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: wonderlaSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: wonderlaMuted),
      labelStyle: const TextStyle(color: wonderlaMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: wonderlaBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: wonderlaBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: wonderlaCobalt, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: wonderlaFlagRed),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: wonderlaCobalt,
        side: const BorderSide(color: wonderlaBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: wonderlaWhite,
      selectedColor: wonderlaCobalt,
      side: const BorderSide(color: wonderlaBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: wonderlaNavy),
    ),
    dividerTheme: const DividerThemeData(color: wonderlaBorder, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: wonderlaWhite,
      surfaceTintColor: wonderlaWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: wonderlaWhite,
      surfaceTintColor: wonderlaWhite,
      showDragHandle: true,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: wonderlaCobalt,
      linearTrackColor: wonderlaBorder,
    ),
  );
}
