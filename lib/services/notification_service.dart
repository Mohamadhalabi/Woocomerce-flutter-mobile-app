import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request permission (Crucial for iOS, also required for Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notification permission granted.');
    } else {
      print('Notification permission declined.');
    }

    // 2. Fetch the FCM token for this specific device
    try {
      String? token = await messaging.getToken();
      print("========== FCM DEVICE TOKEN ==========");
      print(token);
      print("======================================");
      // TODO: Send this token to your backend server to save with the user's profile
    } catch (e) {
      print("Failed to get FCM token: $e");
    }

    // 3. Listen for foreground messages (when the app is open and active)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
      }
    });
  }
}