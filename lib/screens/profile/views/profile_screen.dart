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
            } else if (userSnapshot.hasError || userSnapshot.data == null) {
              return const ColoredBox(
                color: Colors.white,
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

  Widget _buildGuestView() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _cardItem(
              icon: Icons.login,
              title: 'Giriş Yap',
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
            _cardItem(
              icon: Icons.person_add,
              title: 'Kayıt Ol',
              onTap: () => Navigator.pushNamed(context, '/register'),
            ),
            const SizedBox(height: 20),
            _buildCurrencySelector(),
            _staticCardItem(Icons.favorite_border, 'İstek Listem'),
            _staticCardItem(Icons.message_outlined, 'Bildirim Mesajları'),
            _staticCardItem(Icons.info_outline, 'Hakkımızda'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(Map<String, dynamic> user) {
    final hasName = (user['name']?.isNotEmpty == true);
    final hasSurname = (user['surname']?.isNotEmpty == true);
    final fullName = "${user['name'] ?? ''} ${user['surname'] ?? ''}".trim();
    final displayName = (hasName || hasSurname) ? fullName : user['email'];

    return SafeArea(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _cardItem(
              icon: Icons.person,
              title: displayName,
              subtitle: (hasName || hasSurname) ? user['email'] ?? '' : '',
              onTap: null,
            ),
            _cardItem(
              icon: Icons.list_alt,
              title: 'Siparişlerim',
              onTap: () async {
                try {
                  final orders = await ApiService.fetchUserOrders();
                  Navigator.pushNamed(context, '/orders', arguments: orders);
                } catch (e) {
                  AlertService.showTopAlert(context, 'Siparişler alınamadı: $e', isError: true);
                }
              },
            ),
            _cardItem(
              icon: Icons.logout,
              title: 'Çıkış Yap',
              onTap: _logout,
            ),
            const SizedBox(height: 20),
            _buildCurrencySelector(),
            _staticCardItem(Icons.favorite_border, 'İstek Listem'),
            _staticCardItem(Icons.message_outlined, 'Bildirim Mesajları'),
            _staticCardItem(Icons.info_outline, 'Hakkımızda'),
          ],
        ),
      ),
    );
  }

  Widget _cardItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title),
        subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _staticCardItem(IconData icon, String title) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(title),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.grey),
        title: const Text('Para Birimi', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
