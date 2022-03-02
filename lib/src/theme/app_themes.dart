import 'package:flutter/material.dart';

class AppThemes {
  
  /// El tema claro de la app, con los colores definidos.
  static final ThemeData appLightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.white,
    dividerColor: const Color(0x22000000),
    
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xFF29B6F6),
      secondary: const Color(0xFF6FD873),
      surface: const Color(0xFFF8F8F8),
      onBackground: const Color(0xFF0F0F0F),
      onSurface: Colors.black54,
      error: const Color(0xFFB00020),
      onError: const Color(0xFFF1F1F1)
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(
        color: Color(0xFF0F0F0F),
      ),
      actionsIconTheme: IconThemeData(
        color: Color(0xFF0F0F0F),
      )
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 5.0,
      showUnselectedLabels: false,
      backgroundColor: Color(0xFFF8F8F8),
    ),
    
    textTheme: const TextTheme(
      headline1: TextStyle(color: Color(0xFF0F0F0F), fontSize: 24.0, fontWeight: FontWeight.w700),
      headline2: TextStyle(color: Color(0xFF0F0F0F), fontSize: 24.0, fontWeight: FontWeight.w700),
      headline3: TextStyle(color: Color(0xFF0F0F0F), fontSize: 24.0, fontWeight: FontWeight.w700),
      headline4: TextStyle(color: Color(0xFF0F0F0F), fontSize: 24.0, fontWeight: FontWeight.w700),
      headline5: TextStyle(color: Color(0xFF0F0F0F), fontSize: 22.0, fontWeight: FontWeight.w400),
      headline6: TextStyle(color: Color(0xFF0F0F0F), fontSize: 20.0, fontWeight: FontWeight.w400),
      bodyText1: TextStyle(color: Color(0xFF0F0F0F), fontSize: 16.0, fontWeight: FontWeight.w400),
      bodyText2: TextStyle(color: Color(0xFF0F0F0F), fontSize: 14.0, fontWeight: FontWeight.w400),
      subtitle1: TextStyle(color: Color(0xFF0F0F0F), fontSize: 16.0),
      subtitle2: TextStyle(color: Colors.green),
      caption: TextStyle(color: Colors.blue),
      overline: TextStyle(color: Colors.purple),
      button: TextStyle(color: Colors.amber),
    )
  );

  /// El tema oscuro de la app, con los colores definidos.
  static final ThemeData appDarkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    dividerColor: const Color(0xFFEFEFEF),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF29292D),
      iconTheme: IconThemeData(
        color: Color(0xFFEFEFEF),
      ),
      actionsIconTheme: IconThemeData(
        color: Color(0xFFEFEFEF),
      ),
    ),

    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xFF29B6F6),
      primaryVariant: const Color(0xFF1998D2),
      secondary: const Color(0xFF6FD873),
      secondaryVariant: const Color(0xFF63C166),
      surface: const Color(0xFF29292D),
      onBackground: const Color(0xFFEFEFEF),
      onSurface: const Color(0x88D6C3C3),
      error: const Color(0xFFB00020),
      onError: const Color(0xFFF1F1F1),
      onPrimary: Colors.white,
      onSecondary: const Color(0xFFFEFEFE),
    ),

    iconTheme: const IconThemeData(
      color: Color(0xFFEFEFEF),
    ),

    textTheme: const TextTheme(
      headline4: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700),
      headline5: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w400),
      headline6: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400),
      bodyText1: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
      bodyText2: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 2.0,
      backgroundColor: Color(0xFF29292D),
    ),
  );
}