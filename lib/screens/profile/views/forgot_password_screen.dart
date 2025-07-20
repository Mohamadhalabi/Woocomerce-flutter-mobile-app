import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../services/alert_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  final Color primaryColor = const Color(0xFF2D83B0);

  Future<void> sendResetEmail() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://www.aanahtar.com.tr/wp-json/custom/v1/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        AlertService.showTopAlert(
          context,
          'Şifre sıfırlama bağlantısı gönderildi.',
          isError: false,
        );
      } else {
        throw data['message'] ?? 'Bir hata oluştu';
      }
    } catch (e) {
      AlertService.showTopAlert(
        context,
        e.toString(),
        isError: true,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // changes text + icon color
        iconTheme: const IconThemeData(color: Colors.white), // back icon color
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta adresinizi girin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sıfırlama Bağlantısı Gönder'),
            )
          ],
        ),
      ),
    );
  }
}