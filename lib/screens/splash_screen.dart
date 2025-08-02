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
        final user = await ApiService.fetchUserInfo();
        _userData = user;
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