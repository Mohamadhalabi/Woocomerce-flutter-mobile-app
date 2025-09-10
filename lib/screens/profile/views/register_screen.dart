import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/route/screen_export.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';
import 'login_screen.dart';
import '../../../services/alert_service.dart';
import 'verify_code_screen.dart';

/// Formats phone input like: (555) 1234567
class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Keep digits only
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    // Build "(xxx) rest"
    String formatted;
    if (digits.length <= 3) {
      formatted = '(${digits}';
    } else {
      final head = digits.substring(0, 3);
      final tail = digits.substring(3);
      formatted = '($head) $tail';
    }

    // Place cursor at end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController  = TextEditingController();
  final emailController     = TextEditingController();
  final passwordController  = TextEditingController();
  final phoneController     = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final primaryColor = const Color(0xFF2D83B0);

  static const int profileIndex = 4;

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  String? _requiredValidator(String? v, {int min = 1}) {
    final t = v?.trim() ?? '';
    if (t.length < min) return 'Bu alan zorunludur';
    return null;
  }

  String? _passwordValidator(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Şifre zorunludur';
    if (t.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }

  String? _phoneValidator(String? v) {
    final digits = _digitsOnly(v ?? '');
    if (digits.isEmpty) return 'Telefon zorunludur';
    if (digits.startsWith('0')) return 'Telefon 0 ile başlayamaz';
    if (digits.length < 10) return 'Telefon en az 10 haneli olmalı';
    return null;
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) {
      AlertService.showTopAlert(context, 'Lütfen zorunlu alanları doldurun.', isError: true);
      return;
    }

    final phoneDigits = _digitsOnly(phoneController.text);

    setState(() => isLoading = true);
    try {
      await ApiService.registerWithPhone(
        phone: phoneDigits, // ✅ sanitized
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        password: passwordController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName:  lastNameController.text.trim(),
      );

      if (!mounted) return;
      AlertService.showTopAlert(context, 'Kod gönderildi', isError: false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            phoneNumber: phoneDigits, // ✅ sanitized
            isFromRegister: true,
            firstName: firstNameController.text.trim(),
            lastName:  lastNameController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Kayıt Ol', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 30),
              Center(child: Image.asset('assets/logo/aanahtar-logo.webp', height: 70)),
              const SizedBox(height: 40),

              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'Ad*'),
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Soyad*'),
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası*',
                  hintText: '(555) 1234567', // ✅ placeholder
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [PhoneFormatter()], // ✅ auto format (xxx)
                validator: _phoneValidator,          // ✅ validation rules
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-posta (Opsiyonel)'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Şifre*'),
                obscureText: true,
                validator: _passwordValidator,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kayıt Ol'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Zaten bir hesabınız var mı?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
          currentIndex: profileIndex,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EntryPoint(
                  onLocaleChange: (_) {},
                  initialIndex: index,
                ),
              ),
            );
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: theme.unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mağaza"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }
}
