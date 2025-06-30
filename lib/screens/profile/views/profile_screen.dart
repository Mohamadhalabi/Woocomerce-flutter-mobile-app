import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Function(int) onTabChange;
  final TextEditingController searchController;

  const ProfileScreen({
    super.key,
    required this.onLocaleChange,
    required this.onTabChange,
    required this.searchController,
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
    widget.onTabChange(0); // Go to home tab
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("📱 ProfileScreen build started");

    return FutureBuilder<String?>(
      future: _getToken(),
      builder: (context, snapshot) {
        debugPrint("📱 Token snapshot: hasData=${snapshot.hasData}, value=${snapshot.data}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: Colors.white,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token == null || token.isEmpty) {
          debugPrint("📱 No token → guest view");
          return _buildGuestView();
        }

        debugPrint("📱 Token exists → fetching user info");

        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.fetchUserInfo(),
          builder: (context, userSnapshot) {
            debugPrint("📱 User fetch: state=${userSnapshot.connectionState}, hasError=${userSnapshot.hasError}");

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (userSnapshot.hasError) {
              debugPrint("❌ User fetch error: ${userSnapshot.error}");
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: Text("Kullanıcı bilgileri alınamadı")),
              );
            }

            final user = userSnapshot.data;
            if (user == null) {
              debugPrint("❌ user is null");
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: Text("Geçersiz kullanıcı verisi")),
              );
            }

            debugPrint("✅ User fetched: ${user['name']}");
            return _buildLoggedInView(user);
          },
        );
      },
    );
  }

  Widget _buildGuestView() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          children: [
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Giriş Yap'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Kayıt Ol'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, '/register'),
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
        ),
      ),
    );
  }

  Widget _buildLoggedInView(Map<String, dynamic> user) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: ListView(
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
        ),
      ),
    );
  }
}