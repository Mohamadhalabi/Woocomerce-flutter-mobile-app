import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import '../entry_point.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Map<String, dynamic>? _drawerData;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    // 1️⃣ Fetch drawer data
    try {
      _drawerData = await fetchDrawerData(lang);
      debugPrint("✅ Splash fetched drawer data");
    } catch (e) {
      debugPrint("❌ Failed to fetch drawer data: $e");
    }

    // 2️⃣ Check login and fetch user profile
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
        // 1️⃣ Fetch basic user info
        final user = await ApiService.fetchUserInfo();
        _userData = user;

        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('user_id', user['id']);

        // 2️⃣ Fetch billing info from WooCommerce
        try {
          final billingData = await ApiService.fetchUserBilling(); // This returns full WooCommerce customer data
          if (billingData['billing'] != null) {
            _userData!['billing'] = billingData['billing'];

            // 3️⃣ Save billing info to SharedPreferences for CheckoutScreen
            final billing = billingData['billing'];
            prefs.setString('billing_first_name', billing['first_name'] ?? '');
            prefs.setString('billing_last_name', billing['last_name'] ?? '');
            prefs.setString('billing_address_1', billing['address_1'] ?? '');
            prefs.setString('billing_postcode', billing['postcode'] ?? '');
            prefs.setString('billing_city', billing['city'] ?? '');
            prefs.setString('billing_country', billing['country'] ?? 'Türkiye');
            prefs.setString('billing_phone', billing['phone'] ?? '');
            prefs.setString('billing_email', billing['email'] ?? '');
          }
        } catch (e) {
          debugPrint("❌ Failed to fetch billing info: $e");
        }

        debugPrint("✅ Splash fetched user data: $_userData");
      } else {
        debugPrint("ℹ️ No valid login token, skipping user fetch");
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch user profile: $e");
    }

    // 3️⃣ Keep splash visible a bit
    await Future.delayed(const Duration(seconds: 2));

    // 4️⃣ Go to EntryPoint
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EntryPoint(
          onLocaleChange: (_) {},
          initialDrawerData: _drawerData,
          initialUserData: _userData,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchDrawerData(String lang) async {
    final url = Uri.parse(
      'https://www.aanahtar.com.tr/wp-json/custom/v1/drawer-data?lang=$lang',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch drawer data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A72B7),
      body: Center(
        child: Image.asset('assets/splash/splash.png'),
      ),
    );
  }
}