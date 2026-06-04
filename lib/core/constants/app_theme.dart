import 'package:flutter/material.dart';
import '../../util/colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: themeColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: themeColor,
      primary: themeColor,
    ),
    scaffoldBackgroundColor: whiteColor,
    appBarTheme: AppBarTheme(
      backgroundColor: themeColor,
      foregroundColor: whiteColor,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: themeColor,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: themeColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: themeColor,
      primary: themeColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: blackColor,
    appBarTheme: AppBarTheme(
      backgroundColor: blackColor,
      foregroundColor: whiteColor,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: themeColor,
    ),
  );
}
