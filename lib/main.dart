import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/providers/currency_provider.dart';
import 'package:shop/providers/wishlist_provider.dart';
import 'package:shop/screens/splash_screen.dart';
import 'package:shop/services/api_initializer.dart';
import 'package:shop/theme/app_theme.dart';
import 'package:shop/route/router.dart' as router;

import "controllers/locale_controller.dart";
import 'package:shop/screens/search/views/components/search_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await initApiClient();

  // ✅ Load locksmith mapping JSON before app starts
  await SearchForm.loadLocksmithMapping();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = WishlistProvider();
            provider.loadWishlist(); // ✅ explicitly called here
            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // ✅ Allow ProfileScreen or other widgets to toggle theme
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static void Function(String)? updateLocale;

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.light; // ✅ default theme

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _loadTheme();
    LocaleController.updateLocale = _setLocale;
  }

  /// ✅ Load saved language
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('lang_code');
    if (langCode != null) {
      setState(() {
        _locale = Locale(langCode);
      });
    }
  }

  /// ✅ Save language
  Future<void> _setLocale(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_code', langCode);
    setState(() {
      _locale = Locale(langCode);
    });
  }

  /// ✅ Load saved theme mode
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'light';
    setState(() {
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  /// ✅ Save and apply theme mode
  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    setState(() {
      _themeMode = mode;
    });
  }

  /// ✅ Toggle between light and dark mode
  void toggleTheme() {
    final newMode =
    _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      title: 'Anadolu Anahtar',

      // ✅ Use your existing AppTheme definitions
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context), // You'll create this in app_theme.dart
      themeMode: _themeMode, // ✅ dynamic mode

      onGenerateRoute: router.generateRoute,
      home: const SplashScreen(),
    );
  }
}