// lib/screens/profile/views/forgot_password_screen_v2.dart
//
// POST /auth/forgot-password.
//
// The API deliberately returns the same message whether or not the address is
// registered — a different response for unknown emails tells an attacker which
// addresses exist. So there's no "email not found" state to handle here.

import 'package:flutter/material.dart';

import '../../../services/alert_service.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';

class ForgotPasswordScreenV2 extends StatefulWidget {
  const ForgotPasswordScreenV2({super.key});

  @override
  State<ForgotPasswordScreenV2> createState() => _ForgotPasswordScreenV2State();
}

class _ForgotPasswordScreenV2State extends State<ForgotPasswordScreenV2> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _sent = false;

  final Color primaryColor = const Color(0xFF2D83B0);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final message = await authRepo.forgotPassword(_emailController.text);

      if (!mounted) return;
      setState(() => _sent = true);
      AlertService.showTopAlert(context, message, isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _sentView() : _formView(),
      ),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hesabınıza kayıtlı e-posta adresini girin. Şifre sıfırlama '
            'bağlantısını size gönderelim.',
            style: TextStyle(fontSize: 13.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-posta adresiniz',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'E-posta zorunludur';
              if (!t.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
            onFieldSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Sıfırlama Bağlantısı Gönder'),
          ),
        ],
      ),
    );
  }

  Widget _sentView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 56, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Bağlantı gönderildi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'E-posta adresiniz kayıtlıysa şifre sıfırlama bağlantısı '
          'gönderilmiştir. Gelen kutunuzu ve spam klasörünü kontrol edin.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Giriş ekranına dön'),
        ),
      ],
    );
  }
}
