import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shop/constants.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/currency_provider.dart';
import '../../../main.dart'; // ✅ Needed for MyApp.of(context)?.toggleTheme()

class ProfileScreen extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Function(int) onTabChange;
  final TextEditingController searchController;
  final Map<String, dynamic>? initialUserData; // ✅ Keep initialUserData

  const ProfileScreen({
    super.key,
    required this.onLocaleChange,
    required this.onTabChange,
    required this.searchController,
    this.initialUserData,
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
    widget.onTabChange(4);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ If splash gave us preloaded user data, show instantly
    if (widget.initialUserData != null) {
      return _buildProfileView(isLoggedIn: true, user: widget.initialUserData!);
    }

    return FutureBuilder<String?>(
      future: _getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;

        if (token != null &&
            token.isNotEmpty &&
            !JwtDecoder.isExpired(token)) {
          return FutureBuilder<Map<String, dynamic>>(
            future: ApiService.fetchUserInfo(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              if (userSnapshot.hasError || userSnapshot.data == null) {
                return _buildProfileView(isLoggedIn: false);
              }
              return _buildProfileView(
                isLoggedIn: true,
                user: userSnapshot.data!,
              );
            },
          );
        } else {
          return _buildProfileView(isLoggedIn: false);
        }
      },
    );
  }

  Widget _buildProfileView({required bool isLoggedIn, Map<String, dynamic>? user}) {
    final name = user?['name'] ?? '';
    final surname = user?['surname'] ?? '';
    final email = user?['email'] ?? '';
    final displayName = isLoggedIn
        ? (name.isNotEmpty || surname.isNotEmpty)
        ? '$name $surname'.trim()
        : email
        : 'Misafir Kullanıcı';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withOpacity(0.15),
                child: Icon(Icons.person, color: Theme.of(context).iconTheme.color, size: 28),
              ),
              title: Text(
                displayName,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              subtitle: isLoggedIn
                  ? Text(email,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))
                  : Text("Henüz giriş yapmadınız",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: isLoggedIn ? Icon(Icons.edit, size: 20, color: Theme.of(context).iconTheme.color) : null,
            ),
          ),

          const SizedBox(height: 16),

          // Guest login/register row
          if (!isLoggedIn) ...[
            Row(
              children: [
                Expanded(
                  child: _cardItem(Icons.login, 'Giriş Yap',
                      onTap: () => Navigator.pushNamed(context, '/login')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _cardItem(Icons.person_add, 'Kayıt Ol',
                      onTap: () => Navigator.pushNamed(context, '/register')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _cardItem(Icons.favorite_border, 'İstek Listem',
                onTap: () => Navigator.pushNamed(context, '/login')),
          ],

          // Logged-in only
          if (isLoggedIn) ...[
            _cardItem(Icons.list_alt, 'Siparişlerim', onTap: () async {
              try {
                final orders = await ApiService.fetchUserOrders();
                Navigator.pushNamed(context, '/orders', arguments: orders);
              } catch (e) {
                AlertService.showTopAlert(context, 'Siparişler alınamadı: $e', isError: true);
              }
            }),
            _cardItem(Icons.favorite_border, 'İstek Listem',
                onTap: () => Navigator.pushNamed(context, '/wishlist')),
            _cardItem(Icons.remove_red_eye_outlined, 'Göz Atma Geçmişi',
                onTap: () => Navigator.pushNamed(context, '/browsing-history')),
            _cardItem(Icons.visibility, 'İncelediğim Ürünler',
                onTap: () => Navigator.pushNamed(context, '/viewed-products')),
          ],

          // Currency selector
          _buildCurrencySelector(),

          // 🌙 Theme toggle
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: SwitchListTile(
              secondary: Icon(Icons.brightness_6, color: Theme.of(context).iconTheme.color),
              title: Text('Karanlık Mod',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (val) {
                MyApp.of(context)?.toggleTheme();
              },
            ),
          ),

          _cardItem(Icons.info_outline, 'Hakkımızda',
              onTap: () => Navigator.pushNamed(context, '/about')),

          // Logout only if logged in
          if (isLoggedIn)
            _cardItem(Icons.logout, 'Çıkış Yap', onTap: _logout),
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
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
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
        leading: Icon(Icons.attach_money, color: Theme.of(context).iconTheme.color),
        title: Text('Para Birimi', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
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

  /// 🔄 Refresh method used by EntryPoint to force UI update
  Future<void> refresh() async {
    setState(() {});
  }
}