import 'package:flutter/material.dart';
import 'package:shop/screens/profile/views/verify_code_screen.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';
import '../../../entry_point.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  final Color primaryColor = const Color(0xFF2D83B0);

  Future<void> sendCode() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.sendLoginCode(phoneController.text.trim());
      if (!mounted) return;

      AlertService.showTopAlert(context, 'Kod gönderildi.', isError: false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(phoneNumber: phoneController.text.trim()),
        ),
      );
    } catch (e) {
      AlertService.showTopAlert(context, e.toString(), isError: true);
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
          'Telefon ile Giriş',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/logo/aanahtar-logo.webp', // Make sure this file exists in your assets folder
                height: 70,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: phoneController,
              decoration: _inputDecoration('Telefon Numarası (05xxxxxxxxx)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kod Gönder'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
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
    );
  }
}
