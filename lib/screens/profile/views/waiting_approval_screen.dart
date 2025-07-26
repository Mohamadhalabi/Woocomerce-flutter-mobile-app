import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';

class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  int _currentIndex = 4;

  void _navigateTo(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EntryPoint(onLocaleChange: (_) {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Onay Bekleniyor',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Kaydınız alınmıştır.\nYönetici onayı bekleniyor.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 12),
              Text(
                'Onaylandıktan sonra giriş yapabilirsiniz.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
