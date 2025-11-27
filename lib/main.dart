import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Keep this if you use AppLocalizations in other files
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/providers/currency_provider.dart';
import 'package:shop/providers/wishlist_provider.dart';
import 'package:shop/screens/splash_screen.dart';
import 'package:shop/services/api_initializer.dart';
import 'package:shop/theme/app_theme.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/screens/search/views/components/search_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await initApiClient();

  await SearchForm.loadLocksmithMapping();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = WishlistProvider();
            provider.loadWishlist();
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

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Removed: static updateLocale function
  // Removed: _locale variable

  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    // Removed: _loadLocale();
    // Removed: LocaleController assignment
    _loadTheme();
  }

  // Removed: _loadLocale and _setLocale functions

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

  void toggleTheme() {
    final newMode =
    _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme(newMode);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anadolu Anahtar',

      // ✅ FIX 1: Use 'tr' only (standard format), not 'tr_TR'
      locale: const Locale('tr'),

      // ✅ FIX 2: Use the auto-generated lists.
      // Even if this list includes English, setting 'locale' above forces Turkish.
      // This prevents the "Null" error because it ensures the 'tr' delegate is actually loaded.
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // ✅ FIX 3: Force LTR (Left-to-Right) layout
      // This fixes the reversed images on RTL devices
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox(), // Add null safety check here just in case
        );
      },

      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: _themeMode,

      onGenerateRoute: router.generateRoute,
      home: const SplashScreen(),
    );
  }
}