import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Function(int) onTabChange;

  const ProfileScreen({
    super.key,
    required this.onLocaleChange,
    required this.onTabChange,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => EntryPoint(onLocaleChange: (_) {}),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<String?>(
        future: _getToken(),
        builder: (context, snapshot) {
          final token = snapshot.data;
          if (!snapshot.hasData || token == null || token.isEmpty) {
            return _buildGuestView();
          } else {
            return FutureBuilder<Map<String, dynamic>>(
              future: ApiService.fetchUserInfo(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (userSnapshot.hasError) {
                  return Center(child: Text("Hata: ${userSnapshot.error}"));
                } else {
                  final user = userSnapshot.data!;
                  return _buildLoggedInView(user);
                }
              },
            );
          }
        },
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 4,
      //   onTap: (index) {
      //     if (index != 4) {
      //       widget.onTabChange(index);
      //     }
      //   },
      //   selectedItemColor: primaryColor,
      //   unselectedItemColor: Colors.grey,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Mağaza"),
      //     BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
      //     BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Kaydedilenler"),
      //     BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      //   ],
      // ),
    );
  }

  Widget _buildGuestView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      children: [
        ListTile(
          leading: const Icon(Icons.login),
          title: const Text('Giriş Yap'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person_add),
          title: const Text('Kayıt Ol'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.pushNamed(context, '/register');
          },
        ),
        const Divider(height: 32),
        const ListTile(
          leading: Icon(Icons.favorite_border),
          title: Text('İstek Listem'),
        ),
        const ListTile(
          leading: Icon(Icons.message_outlined),
          title: Text('Bildirim Mesajları'),
        ),
        const ListTile(
          leading: Icon(Icons.star_border),
          title: Text('Uygulamayı Puanla'),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Hakkımızda'),
        ),
      ],
    );
  }

  Widget _buildLoggedInView(Map<String, dynamic> user) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(user['name'] ?? 'Profilim'),
          subtitle: Text(user['email'] ?? ''),
        ),
        ListTile(
          leading: const Icon(Icons.list_alt),
          title: const Text('Siparişlerim'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () async {
            try {
              final orders = await ApiService.fetchUserOrders();
              Navigator.pushNamed(context, '/orders', arguments: orders);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Siparişler alınamadı: $e')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Çıkış Yap'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _logout,
        ),
        const Divider(height: 32),
        const ListTile(
          leading: Icon(Icons.favorite_border),
          title: Text('İstek Listem'),
        ),
        const ListTile(
          leading: Icon(Icons.message_outlined),
          title: Text('Bildirim Mesajları'),
        ),
        const ListTile(
          leading: Icon(Icons.star_border),
          title: Text('Uygulamayı Puanla'),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Hakkımızda'),
        ),
      ],
    );
  }
}