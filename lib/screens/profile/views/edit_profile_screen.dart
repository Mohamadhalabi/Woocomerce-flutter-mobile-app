import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/services/alert_service.dart';
import 'package:shop/entry_point.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user; // pass current user info

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  final TextEditingController passwordController = TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user['first_name'] ?? '');
    lastNameController  = TextEditingController(text: widget.user['last_name']  ?? '');
    emailController     = TextEditingController(text: widget.user['email']      ?? '');
    phoneController     = TextEditingController(text: widget.user['phone']      ?? '');
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: theme.textTheme.bodyMedium?.color,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Future<void> _save() async {
    if (firstNameController.text.trim().isEmpty) {
      AlertService.showTopAlert(context, "Ad boş olamaz", isError: true);
      return;
    }
    if (lastNameController.text.trim().isEmpty) {
      AlertService.showTopAlert(context, "Soyad boş olamaz", isError: true);
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      AlertService.showTopAlert(context, "Telefon boş olamaz", isError: true);
      return;
    }

    setState(() => isSaving = true);
    try {
      await ApiService.updateUserProfile(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim().isEmpty
            ? null
            : passwordController.text.trim(),
      );

      if (!mounted) return;
      AlertService.showTopAlert(context, 'Profil güncellendi', isError: false);
      Navigator.pop(context, true);
    } catch (e) {
      AlertService.showTopAlert(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Bilgilerini Düzenle",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16, // 👈 smaller font size
            fontWeight: FontWeight.w500, // optional: make it medium weight
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              decoration: _inputDecoration("Ad *"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: lastNameController,
              decoration: _inputDecoration("Soyad *"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              decoration: _inputDecoration("E-posta"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneController,
              decoration: _inputDecoration("Telefon *"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: _inputDecoration("Şifre (Opsiyonel)"),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("İptal"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving ? null : _save,
                    child: isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Kaydet", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
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
