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
    // Precache splash image for a crisp instant render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/splash/splash.png'), context);
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    // 1) Drawer data
    try {
      _drawerData = await fetchDrawerData(lang);
      debugPrint("✅ Splash fetched drawer data");
    } catch (e) {
      debugPrint("❌ Failed to fetch drawer data: $e");
    }

    // 2) User & billing (if logged in)
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
        final user = await ApiService.fetchUserInfo();
        _userData = user;

        prefs.setInt('user_id', user['id']);

        try {
          final billingData = await ApiService.fetchUserBilling();
          if (billingData['billing'] != null) {
            _userData!['billing'] = billingData['billing'];
            final b = billingData['billing'];
            prefs
              ..setString('billing_first_name', b['first_name'] ?? '')
              ..setString('billing_last_name', b['last_name'] ?? '')
              ..setString('billing_address_1', b['address_1'] ?? '')
              ..setString('billing_postcode', b['postcode'] ?? '')
              ..setString('billing_city', b['city'] ?? '')
              ..setString('billing_country', b['country'] ?? 'Türkiye')
              ..setString('billing_phone', b['phone'] ?? '')
              ..setString('billing_email', b['email'] ?? '');
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

    // 3) Keep splash visible a bit
    await Future.delayed(const Duration(seconds: 2));

    // 4) Navigate
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
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash/splash.png',
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
