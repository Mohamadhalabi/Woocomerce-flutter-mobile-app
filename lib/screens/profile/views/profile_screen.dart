import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shop/constants.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/currency_provider.dart';
import '../../../main.dart';
import '../../about/hakkimizda_screen.dart';
import '../../../entry_point.dart';
import 'edit_profile_screen.dart';
import 'address_edit_screen.dart'; // ✅ new screen

class ProfileScreen extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Function(int) onTabChange;
  final TextEditingController searchController;
  final Map<String, dynamic>? initialUserData;

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
  void refresh() {
    if (mounted) setState(() {});
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

    setState(() {
      widget.initialUserData?.clear();
    });

    AlertService.showTopAlert(
      context,
      'Başarıyla çıkış yapıldı',
      isError: false,
    );
  }

  // ---------- UI helpers ----------
  Widget _sectionTitle(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  BoxDecoration _cardDec(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      boxShadow: [
        BoxShadow(
          color: theme.brightness == Brightness.dark
              ? Colors.black.withOpacity(0.3)
              : Colors.black12,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _actionTile(IconData icon, String title, {VoidCallback? onTap, Color? iconBg}) {
    final theme = Theme.of(context);
    return Container(
      decoration: _cardDec(context),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: iconBg ?? primaryColor.withOpacity(0.12),
          child: Icon(icon, color: theme.iconTheme.color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color),
        onTap: onTap,
      ),
    );
  }

  Widget _profileHeader({required bool isLoggedIn, required String displayName, required String? email}) {
    final theme = Theme.of(context);
    return Container(
      decoration: _cardDec(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryColor.withOpacity(0.15),
            child: Icon(Icons.person, color: theme.iconTheme.color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyMedium?.color,
                    )),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn ? (email ?? '') : "Henüz giriş yapmadınız",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isLoggedIn)
            IconButton(
              tooltip: "Bilgilerini Düzenle",
              icon: Icon(Icons.edit, size: 20, color: theme.iconTheme.color),
              onPressed: () async {
                final user = await ApiService.fetchUserInfo();
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                );
                if (result == true && mounted) setState(() {});
              },
            ),
        ],
      ),
    );
  }
  // --------------------------------

  @override
  Widget build(BuildContext context) {
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

        if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
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
    final name = user?['first_name'] ?? '';
    final surname = user?['last_name'] ?? '';
    final email = user?['email'] ?? '';
    final displayName = isLoggedIn
        ? (name.isNotEmpty || surname.isNotEmpty)
        ? '$name $surname'.trim()
        : email
        : 'Misafir Kullanıcı';

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileHeader(isLoggedIn: isLoggedIn, displayName: displayName, email: email),
          const SizedBox(height: 10),

          if (!isLoggedIn) ...[
            _sectionTitle("Hızlı İşlemler"),
            Row(
              children: [
                Expanded(
                  child: _actionTile(Icons.login, 'Giriş Yap',
                      onTap: () => Navigator.pushNamed(context, '/login'), iconBg: Colors.green.withOpacity(0.12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionTile(Icons.person_add, 'Kayıt Ol',
                      onTap: () => Navigator.pushNamed(context, '/register'), iconBg: Colors.blue.withOpacity(0.12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _actionTile(Icons.favorite_border, 'İstek Listem',
                onTap: () => Navigator.pushNamed(context, '/wishlist')),
          ],

          if (isLoggedIn) ...[
            _sectionTitle("Hesabım"),
            _actionTile(Icons.location_on, 'Adresim', onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddressEditScreen()),
              );
              if (result == true && mounted) setState(() {});
            }),
            _actionTile(Icons.list_alt, 'Siparişlerim', onTap: () {
              Navigator.pushNamed(context, '/orders');
            }),
            _actionTile(Icons.favorite_border, 'İstek Listem',
                onTap: () => Navigator.pushNamed(context, '/wishlist')),
          ],

          _sectionTitle("Tercihler"),
          // currency
          Container(
            decoration: _cardDec(context),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange.withOpacity(0.12),
                child: Icon(Icons.attach_money, color: theme.iconTheme.color),
              ),
              title: Text('Para Birimi',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
              trailing: DropdownButton<String>(
                value: _selectedCurrency,
                underline: const SizedBox(),
                items: ['TRY', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (newCurrency) {
                  if (newCurrency != null) _updateCurrency(newCurrency);
                },
              ),
            ),
          ),

          Container(
            decoration: _cardDec(context),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: SwitchListTile(
              secondary: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple.withOpacity(0.12),
                child: Icon(Icons.brightness_6, color: theme.iconTheme.color),
              ),
              title: Text('Karanlık Mod',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
              value: theme.brightness == Brightness.dark,
              onChanged: (val) => MyApp.of(context)?.toggleTheme(),
            ),
          ),

          _sectionTitle("Diğer"),
          _actionTile(Icons.info_outline, 'Hakkımızda', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HakkimizdaScreen(onLocaleChange: (_) {})),
            );
          }),
          if (isLoggedIn)
            _actionTile(Icons.logout, 'Çıkış Yap',
                onTap: _logout, iconBg: Colors.red.withOpacity(0.12)),
        ],
      ),
    );
  }
}
