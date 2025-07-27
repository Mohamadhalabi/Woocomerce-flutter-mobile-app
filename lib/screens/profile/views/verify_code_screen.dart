import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';
import '../../../services/cart_service.dart';
import '../complete_profile_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isFromRegister;

  const VerifyCodeScreen({
    super.key,
    required this.phoneNumber,
    this.isFromRegister = false,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;
  final Color primaryColor = const Color(0xFF2D83B0);

  int secondsRemaining = 60;
  Timer? _timer;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      secondsRemaining = 60;
      canResend = false;
    });

    _timer?.cancel(); // clear old timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        setState(() => canResend = true);
        _timer?.cancel();
      }
    });
  }

  Future<void> resendCode() async {
    try {
      await ApiService.sendLoginCode(widget.phoneNumber);
      AlertService.showTopAlert(context, 'Kod yeniden gönderildi.', isError: false);
      _startTimer();
    } catch (e) {
      AlertService.showTopAlert(context, e.toString(), isError: true);
    }
  }

  Future<void> verifyCode() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.verifyLoginCode(
        phone: widget.phoneNumber,
        code: codeController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result['token']);

      final guestCart = await CartService.getGuestCart();
      for (var item in guestCart) {
        final productId = item['productId'];
        final rawQty = item['quantity'];
        if (productId == null || rawQty == null) continue;

        int quantity = int.tryParse(rawQty.toString()) ?? 1;
        await CartService.addToWooCart(result['token'], productId, quantity);
      }

      await CartService.clearGuestCart();

      if (!mounted) return;

      AlertService.showTopAlert(context, 'Giriş başarılı', isError: false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(token: result['token']),
        ),
      );
    } catch (e) {
      AlertService.showTopAlert(context, e.toString(), isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    codeController.dispose();
    super.dispose();
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
        title: const Text('Kod Doğrulama', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/logo/aanahtar-logo.webp',
                height: 70,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Gelen Kodu Girin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (!canResend)
              Text(
                'Tekrar kod göndermek için ${secondsRemaining}s',
                style: const TextStyle(color: Colors.grey),
              ),
            if (canResend)
              TextButton(
                onPressed: resendCode,
                child: Text('Yeniden Kod Gönder', style: TextStyle(color: primaryColor)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Doğrula ve Giriş Yap'),
            ),
          ],
        ),
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