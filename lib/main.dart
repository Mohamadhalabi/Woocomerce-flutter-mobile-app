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
import 'package:shop/screens/search/views/components/search_form.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Local Notifications Import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Import your Notification Provider
import 'package:shop/providers/notification_provider.dart';

// --- SETUP LOCAL NOTIFICATIONS ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);
// ---------------------------------

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- INITIALIZE LOCAL NOTIFICATIONS FOR FOREGROUND ---
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await dotenv.load();
  await initApiClient();
  await SearchForm.loadLocksmithMapping();

  // --- TEMPORARY DEBUG CODE TO GET TOKEN ---
  try {
    await FirebaseMessaging.instance.requestPermission();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("====================================");
    print("FCM TOKEN: $fcmToken");
    print("====================================");
  } catch (e) {
    print("Failed to get token: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    // ✅ Initialize notification listeners
    _setupNotificationInteractions();
  }

  // ✅ IMPROVED: Handles saving notifications in all app states
  void _setupNotificationInteractions() {
    // 1. Handle messages while the app is actively OPEN (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _processNotification(message);
    });

    // 2. Handle when the user CLICKS a notification from the tray while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _processNotification(message);
    });

    // 3. Handle "Cold Starts" - when app was closed and opened via a notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _processNotification(message);
      }
    });
  }

  // ✅ Helper to save to provider and show local banner
  void _processNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // SAVE TO HISTORY: This ensures it appears in the "Bildirimler" screen
      Provider.of<NotificationProvider>(context, listen: false)
          .addNotification(notification.title ?? "", notification.body ?? "");

      // SHOW LOCAL BANNER: Only if the app is in the foreground
      if (android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'light';
    setState(() {
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anadolu Anahtar',
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox(),
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