import 'package:flutter/material.dart';
import 'package:shop/theme/button_theme.dart';
import 'package:shop/theme/input_decoration_theme.dart';

import '../constants.dart';
import 'checkbox_themedata.dart';
import 'theme_data.dart';

class AppTheme {
  // ✅ Light Theme
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      primarySwatch: primaryMaterialColor,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black87),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
      ),

      // ✅ AppBar stays pure white
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),

      // ✅ Bottom Navigation stays pure white
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.black54,
        elevation: 0,
      ),

      // ✅ Drawer stays pure white
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),

      // ✅ Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // ✅ Dark Theme
  static ThemeData darkTheme(BuildContext context) {
    const darkBg = Color(0xFF1E1E1E); // Unified background for header + screen

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: "Poppins",
      primarySwatch: primaryMaterialColor,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBg, // same as header
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      textButtonTheme: textButtonThemeData,
      outlinedButtonTheme: outlinedButtonTheme(),
      inputDecorationTheme: lightInputDecorationTheme.copyWith(
        fillColor: const Color(0xFF2A2A2A), // slightly lighter for fields
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      checkboxTheme: checkboxThemeData.copyWith(
        side: const BorderSide(color: Colors.white54),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg, // same as screen
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBg, // match app bar
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
      scrollbarTheme: scrollbarThemeData,
      dataTableTheme: dataTableLightThemeData,
    );
  }
}