import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/currency_provider.dart';

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
  String _selectedCurrency = 'TRY';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('selected_currency') ?? 'TRY';
    });

  }

  Future<void> _updateCurrency(String newCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', newCurrency);

    if (!mounted) return;

    // ✅ Update the provider to notify all listening widgets
    Provider.of<CurrencyProvider>(context, listen: false)
        .setCurrency(newCurrency);

    setState(() {
      _selectedCurrency = newCurrency;
    });

    AlertService.showTopAlert(
      context,
      'Para birimi güncellendi: $newCurrency',
      isError: false,
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!mounted) return;

    AlertService.showTopAlert(
      context,
      'Başarıyla çıkış yapıldı',
      isError: false,
    );

    widget.onTabChange(0); // Go to home tab
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: Colors.white,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
          SharedPreferences.getInstance().then((prefs) => prefs.remove('auth_token'));
          return _buildGuestView();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.fetchUserInfo(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (userSnapshot.hasError) {
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: Text("Kullanıcı bilgileri alınamadı")),
              );
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: Text("Geçersiz kullanıcı verisi")),
              );
            }

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
            _buildCurrencySelector(),
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
                  AlertService.showTopAlert(
                    context,
                    'Siparişler alınamadı: $e',
                    isError: true,
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
            _buildCurrencySelector(),
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

  Widget _buildCurrencySelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: Colors.grey),
          const SizedBox(width: 12),
          const Text(
            'Para Birimi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _selectedCurrency,
            items: ['TRY', 'USD'].map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(currency),
              );
            }).toList(),
            onChanged: (newCurrency) {
              if (newCurrency != null) _updateCurrency(newCurrency);
            },
          ),
        ],
      ),
    );
  }
}
