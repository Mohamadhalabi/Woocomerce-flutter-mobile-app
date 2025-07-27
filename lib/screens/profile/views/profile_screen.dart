import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shop/constants.dart';
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
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
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

    Provider.of<CurrencyProvider>(context, listen: false).setCurrency(newCurrency);

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

    AlertService.showTopAlert(context, 'Başarıyla çıkış yapıldı', isError: false);
    widget.onTabChange(0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: Color(0xFFF5F5F5),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
          return _buildGuestView();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.fetchUserInfo(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const ColoredBox(
                color: Color(0xFFF5F5F5),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (userSnapshot.hasError || userSnapshot.data == null) {
              return const ColoredBox(
                color: Color(0xFFF5F5F5),
                child: Center(child: Text("Kullanıcı bilgileri alınamadı")),
              );
            }

            final user = userSnapshot.data!;
            return _buildLoggedInView(user);
          },
        );
      },
    );
  }

  Widget _buildLoggedInView(Map<String, dynamic> user) {
    final name = user['name'] ?? '';
    final surname = user['surname'] ?? '';
    final email = user['email'] ?? '';
    final displayName = (name.isNotEmpty || surname.isNotEmpty)
        ? '$name $surname'.trim()
        : email;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.person, size: 32, color: primaryColor),
                title: Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(email),
                trailing: const Icon(Icons.edit, size: 20),
              ),
            ),
          ),

          _quickActions(),

          const SizedBox(height: 20),

          _cardItem(Icons.list_alt, 'Siparişlerim', onTap: () async {
            try {
              final orders = await ApiService.fetchUserOrders();
              Navigator.pushNamed(context, '/orders', arguments: orders);
            } catch (e) {
              AlertService.showTopAlert(context, 'Siparişler alınamadı: $e', isError: true);
            }
          }),

          _cardItem(Icons.favorite_border, 'İstek Listem', onTap: () {
            Navigator.pushNamed(context, '/wishlist');
          }),

          _cardItem(Icons.remove_red_eye_outlined, 'Göz Atma Geçmişi', onTap: () {
            Navigator.pushNamed(context, '/browsing-history');
          }),

          _cardItem(Icons.visibility, 'İncelediğim Ürünler', onTap: () {
            Navigator.pushNamed(context, '/viewed-products');
          }),

          _buildCurrencySelector(),

          _cardItem(Icons.logout, 'Çıkış Yap', onTap: _logout),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _quickActionTile(Icons.list_alt, 'Siparişlerim', () => Navigator.pushNamed(context, '/orders')),
            _quickActionTile(Icons.favorite_border, 'İstekler', () => Navigator.pushNamed(context, '/wishlist')),
            _quickActionTile(Icons.history, 'Geçmiş', () => Navigator.pushNamed(context, '/browsing-history')),
            _quickActionTile(Icons.remove_red_eye, 'İncelemeler', () => Navigator.pushNamed(context, '/viewed-products')),
          ],
        ),
      ),
    );
  }

  Widget _quickActionTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cardItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.black87),
        title: const Text('Para Birimi'),
        trailing: DropdownButton<String>(
          value: _selectedCurrency,
          underline: const SizedBox(),
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
      ),
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardItem(Icons.login, 'Giriş Yap', onTap: () => Navigator.pushNamed(context, '/login')),
          _cardItem(Icons.person_add, 'Kayıt Ol', onTap: () => Navigator.pushNamed(context, '/register')),
          _buildCurrencySelector(),
          _cardItem(Icons.info_outline, 'Hakkımızda'),
        ],
      ),
    );
  }

  /// 🔄 Refresh method used by EntryPoint to force UI update
  Future<void> refresh() async {
    setState(() {});
  }
}