import 'dart:async';
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
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/search/views/components/search_form.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Local Notifications Import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Import your Notification Provider
import 'package:shop/providers/notification_provider.dart';

// --- GLOBAL NAVIGATOR KEY ---
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --- SETUP LOCAL NOTIFICATIONS ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase Init failed: $e");
  }

  // Initialize local notifications BEFORE runApp
  await _initLocalNotifications();

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

  // Non-critical background tasks after UI is shown
  _runBackgroundInitializations();
}

/// Initialize flutter_local_notifications (must run before app starts)
Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: false, // We request manually later
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create Android channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation
  <AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _runBackgroundInitializations() async {
  try {
    await dotenv.load();
    await initApiClient();
    await SearchForm.loadLocksmithMapping();
  } catch (e) {
    debugPrint("Background Task Error: $e");
  }
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
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final messaging = FirebaseMessaging.instance;

    // Step 1 — Request permission (shows iOS popup)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('❌ User denied notification permission');
      return;
    }

    // Step 2 — iOS: wait for APNs token (critical!)
    // APNs token may take a few seconds to arrive on first launch
    String? apnsToken;
    for (int i = 0; i < 10; i++) {
      apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null) break;
      debugPrint('⏳ Waiting for APNs token... attempt ${i + 1}');
      await Future.delayed(const Duration(seconds: 1));
    }

    if (apnsToken != null) {
      debugPrint('✅ APNs Token: $apnsToken');
    } else {
      debugPrint('❌ APNs token is null after 10 attempts — iOS notifications will NOT work');
      // Don't return here — FCM might still work on Android
    }

    // Step 3 — Get FCM token
    final fcmToken = await messaging.getToken();
    debugPrint('====================================');
    debugPrint('FCM TOKEN: $fcmToken');
    debugPrint('====================================');

    // Step 4 — iOS foreground presentation options
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Step 5 — Listen for messages
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Step 6 — Handle notification that launched the app from terminated state
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay to ensure navigator is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleMessageTap(initialMessage);
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    debugPrint('📩 Notification tapped: ${message.data}');

    if (message.data['route'] == 'productDetails') {
      final String? idString = message.data['product_id'];
      final int? productId = int.tryParse(idString ?? '');

      if (productId != null) {
        navigatorKey.currentState?.pushNamed(
          productDetailsScreenRoute,
          arguments: productId,
        );
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    debugPrint('📬 Foreground message received: ${message.notification?.title}');

    final RemoteNotification? notification = message.notification;
    final String? idString = message.data['product_id'];
    final int? productId = int.tryParse(idString ?? '');

    if (notification != null) {
      // Add to in-app notification list
      Provider.of<NotificationProvider>(context, listen: false).addNotification(
        notification.title ?? "",
        notification.body ?? "",
        productId: productId,
      );

      // Show local notification banner (needed for foreground on both platforms)
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
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
        'theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Techno lock keys',
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