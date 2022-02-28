import 'package:flutter/material.dart';

class AppThemes {
  
  /// El tema claro de la app, con los colores definidos.
  static final ThemeData appLightTheme = ThemeData.light().copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      actionsIconTheme: IconThemeData(
        color: Color(0xFF0F0F0F),
      )
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xFF29B6F6),
      secondary: const Color(0xFF6FD873),
      onBackground: const Color(0xFF0F0F0F),
    ),
    dividerColor: const Color(0xFF0F0F0F),
    textTheme: const TextTheme(
      headline4: TextStyle(color: Color(0xFF0F0F0F), fontSize: 24.0, fontWeight: FontWeight.w700)
    )
  );

  /// El tema oscuro de la app, con los colores definidos.
  static final ThemeData appDarkTheme = ThemeData.dark().copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      actionsIconTheme: IconThemeData(
        color: Color(0xFFEFEFEF),
      )
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xFF29B6F6),
      secondary: const Color(0xFF6FD873),
      onBackground: const Color(0xFFEFEFEF),
    ),
    dividerColor: const Color(0xFFEFEFEF),
    textTheme: const TextTheme(
      headline4: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700)
    )
  );
}