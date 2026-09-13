// lib/screens/profile/views/register_screen_v2.dart
//
// Registration against the new API.
//
// Two things differ from the WordPress version:
//   1. Field names. The old app sent a single `name`; this API wants
//      first_name / last_name separately, and `password_confirmation` is
//      required by Laravel's `confirmed` rule.
//   2. No session is created. Accounts start unapproved and can't sign in
//      until an admin approves them, so this ends on a confirmation screen
//      rather than dropping into the app.
//
// Email is REQUIRED and unique here. Phone-only registration needs the
// /auth/phone/register endpoint, which doesn't exist yet.

import 'package:flutter/material.dart';

import '../../../services/alert_service.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import 'login_screen_v2.dart';

class RegisterScreenV2 extends StatefulWidget {
  const RegisterScreenV2({super.key});

  @override
  State<RegisterScreenV2> createState() => _RegisterScreenV2State();
}

class _RegisterScreenV2State extends State<RegisterScreenV2> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  /// Field-level errors from Laravel's 422 validation bag.
  Map<String, dynamic>? _serverErrors;

  final Color primaryColor = const Color(0xFF2D83B0);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  String? _serverError(String field) {
    final list = _serverErrors?[field];
    if (list is List && list.isNotEmpty) return list.first.toString();
    return null;
  }

  Future<void> _register() async {
    setState(() => _serverErrors = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final message = await authRepo.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        companyName: _companyController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );

      if (!mounted) return;
      _showPendingApproval(message);
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.isValidation && e.errors != null) {
        // Re-validate so the messages appear under the right fields.
        setState(() => _serverErrors = e.errors);
        _formKey.currentState!.validate();
      }

      AlertService.showTopAlert(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// The account exists but is unusable until approved, so this is a full
  /// screen rather than a toast — the customer needs to understand they
  /// can't sign in yet.
  void _showPendingApproval(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined,
            size: 40, color: Colors.green),
        title: const Text('Kaydınız Alındı'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreenV2()),
              );
            },
            child: const Text('Giriş Ekranına Dön'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {String? field}) {
    return InputDecoration(
      labelText: label,
      errorText: field == null ? null : _serverError(field),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Kayıt Ol', style: TextStyle(color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset('assets/logo/aanahtar-logo.webp', height: 70),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hesabınız yönetici onayından sonra aktif olacaktır.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _firstNameController,
              decoration: _decoration('Ad*', field: 'first_name'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Bu alan zorunludur' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _lastNameController,
              decoration: _decoration('Soyad', field: 'last_name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailController,
              decoration: _decoration('E-posta*', field: 'email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'E-posta zorunludur';
                if (!t.contains('@')) return 'Geçerli bir e-posta girin';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              decoration: _decoration('Telefon', field: 'phone'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _companyController,
              decoration: _decoration('Firma Adı', field: 'company_name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _passwordController,
              decoration: _decoration('Şifre*', field: 'password'),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = v ?? '';
                if (t.isEmpty) return 'Şifre zorunludur';
                // Matches the API's min:8 rule.
                if (t.length < 8) return 'Şifre en az 8 karakter olmalı';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _passwordConfirmController,
              decoration: _decoration('Şifre Tekrar*'),
              obscureText: true,
              validator: (v) => v != _passwordController.text
                  ? 'Şifreler eşleşmiyor'
                  : null,
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
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
                  : const Text('Kayıt Ol'),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Zaten bir hesabınız var mı?'),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreenV2()),
                  ),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
