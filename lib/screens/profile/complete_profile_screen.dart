import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';
import '../../../entry_point.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String token;

  const CompleteProfileScreen({super.key, required this.token});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final Color primaryColor = const Color(0xFF2D83B0);
  bool isLoading = false;

  Future<void> submitProfile() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      AlertService.showTopAlert(context, 'Ad ve soyad zorunludur.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.updateProfileName(
        token: widget.token,
        firstName: firstName,
        lastName: lastName,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', widget.token);

      if (!mounted) return;

      AlertService.showTopAlert(context, 'Profil tamamlandı', isError: false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => EntryPoint(onLocaleChange: (_) {})),
            (_) => false,
      );
    } catch (e) {
      AlertService.showTopAlert(context, e.toString(), isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // light gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Profil Tamamla', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset('assets/logo/aanahtar-logo.webp', height: 70),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Soyad'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Tamamla ve Devam Et'),
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
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Mağaza"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }
}
