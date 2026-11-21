import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF2A56A8); // biru tua
  static const yellow = Color(0xFFFFC545); // kuning
  static const white = Color(0xFFFFFFFF);
  static const lightBlue = Color(0xFFCEDFFF); // biru muda
  static const grey = Color(0xFF747474); // abu tua
  static const black = Color(0xFF373737);
  static const darkYellow = Color(0xFFFFB716); // kuning tua
  static const red = Color(0xFFD70004);
  static const overlay = Color(0x9E000000); // 000000 @ 62%

  // turunan netral untuk permukaan (tombol disabled, keypad, dsb)
  static const surface = Color(0xFFF0F0F0);
  static const keypad = Color(0xFFDADADA);
  static const redSoft = Color(0xFFFFDADA);
}

class AppTheme {
  static const fontFamily = 'Poppins';

  static ThemeData get light => ThemeData(
        fontFamily: fontFamily,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          primary: AppColors.blue,
          secondary: AppColors.yellow,
          surface: AppColors.white,
          error: AppColors.red,
        ),
        splashFactory: NoSplash.splashFactory,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.blue,
          selectionHandleColor: AppColors.blue,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      );
}
