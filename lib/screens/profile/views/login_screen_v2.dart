// lib/screens/profile/views/login_screen_v2.dart
//
// Email + password against the new Sanctum endpoint, plus a button to the
// SMS-code sign-in (PhoneLoginScreenV2).
//
// Differences from the JWT version:
//   - the token is opaque, so there's no client-side expiry check
//   - unapproved accounts are rejected by the server with their own message
//   - the guest cart merges automatically (ApiClient sends X-Cart-Token)
//   - cached data is cleared on sign in, because prices and home sections are
//     cached per audience and the guest copies are now wrong

import 'package:flutter/material.dart';

import '../../../entry_point.dart';
import '../../../repositories/auth_repository.dart';
import '../../../services/alert_service.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../../services/taxonomy_service.dart';
import 'forgot_password_screen_v2.dart';
import 'phone_login_screen_v2.dart';
import 'register_screen_v2.dart';

class LoginScreenV2 extends StatefulWidget {
  const LoginScreenV2({super.key});

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureText = true;

  final Color primaryColor = const Color(0xFF2D83B0);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = await authRepo.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Prices and home sections are cached per audience on both sides —
      // without this the customer signs in and still sees the guest version.
      await TaxonomyService.onAuthChanged();

      // Claims the guest cart. The server merges it into the customer's on
      // this call, using the X-Cart-Token ApiClient already sends.
      try {
        await cartRepo.fetchOrCreate();
      } catch (_) {
        // A failed merge shouldn't block the sign-in.
      }

      if (!mounted) return;

      AlertService.showTopAlert(
        context,
        'Hoş geldiniz, ${customer.firstName}',
        isError: false,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EntryPoint(onLocaleChange: (_) {})),
      );
    } on PendingApprovalException catch (e) {
      if (!mounted) return;
      _showPendingApproval(e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(
        context,
        e.message,
        isError: true,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// The account is real and the password was right — it just hasn't been
  /// approved. A red toast reads like a failure, so this gets its own dialog.
  void _showPendingApproval(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabınız Onay Bekliyor'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Giriş Yap', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Image.asset('assets/logo/aanahtar-logo.webp', height: 70),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration('E-posta Adresi'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'E-posta zorunludur';
                if (!t.contains('@')) return 'Geçerli bir e-posta girin';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: _inputDecoration('Parola').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureText = !_obscureText),
                ),
              ),
              validator: (v) =>
              (v ?? '').isEmpty ? 'Parola zorunludur' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreenV2(),
                  ),
                ),
                child: Text(
                  'Parolanızı mı unuttunuz?',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
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
                  : const Text('E-posta ile giriş yap'),
            ),

            // SMS-code sign-in: /auth/phone/request-code + verify-code.
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PhoneLoginScreenV2(),
                ),
              ),
              icon: Icon(Icons.sms_outlined, color: primaryColor),
              label: Text(
                'Telefon ile giriş yap',
                style: TextStyle(color: primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Hesabın yok mu? "),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreenV2(),
                    ),
                  ),
                  child: Text(
                    'Kayıt ol',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
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