import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/screens/profile/views/register_screen.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';
import '../../../services/cart_service.dart';
import 'forgot_password_screen.dart';
import '../../../services/alert_service.dart';
import 'package:shop/screens/profile/views/phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscureText = true;

  final Color primaryColor = const Color(0xFF2D83B0);

  Future<void> loginUser() async {
    setState(() => isLoading = true);

    try {
      final token = await ApiService.loginUserWithEmail(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // ✅ Merge guest cart into WooCommerce
      final guestCart = await CartService.getGuestCart();
      for (var item in guestCart) {
        final productId = item['productId'];
        final rawQty = item['quantity'];

        if (productId == null || rawQty == null) continue;

        // ✅ Force to int
        int quantity;
        if (rawQty is int) {
          quantity = rawQty;
        } else if (rawQty is String) {
          quantity = int.tryParse(rawQty) ?? 1;
        } else if (rawQty is Map && rawQty.containsKey('value')) {
          quantity = int.tryParse(rawQty['value'].toString()) ?? 1;
        } else {
          quantity = int.tryParse(rawQty.toString()) ?? 1;
        }

        await CartService.addToWooCart(token, productId, quantity);
      }

      await CartService.clearGuestCart();

      if (!mounted) return;

      AlertService.showTopAlert(
        context,
        'Giriş başarılı',
        isError: false,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EntryPoint(onLocaleChange: (_) {}),
        ),
      );
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
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
        title: const Text(
          'Giriş Yap',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 10),
          Center(
            child: Image.asset('assets/logo/aanahtar-logo.webp', height: 70),
          ),
          const SizedBox(height: 30),

          TextField(
            controller: usernameController,
            decoration: _inputDecoration('E-posta Adresi'),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: passwordController,
            obscureText: obscureText,
            decoration: _inputDecoration('Parola').copyWith(
              suffixIcon: IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() => obscureText = !obscureText);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: Text(
                'Parolanızı mı unuttunuz?',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : loginUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('E-posta ile giriş yap'),
          ),
          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Giriş kodu ile (Telefon)',
              style: TextStyle(color: primaryColor),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
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
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: 4,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => EntryPoint(onLocaleChange: (_) {})),
            );
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Mağaza"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Kaydedilenler"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }
}