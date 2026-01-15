import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/profile/views/privacy_policy_screen.dart';
import 'package:shop/screens/profile/views/terms_of_service_screen.dart';
import '../../../components/skleton/profile/profile_skelton.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/currency_provider.dart';
import '../../../main.dart';
import '../../about/hakkimizda_screen.dart';
import 'edit_profile_screen.dart';
import 'address_edit_screen.dart';
import 'faq_screen.dart';

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
    await prefs.remove('user_id'); // Ensure user_id is also removed

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

  // ✅ NEW: Delete Account Logic
  Future<void> _deleteAccount() async {
    // 1. Show Confirmation Modal
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hesabı Sil"),
          content: const Text(
            "Hesabınızı kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz kaybolacaktır.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Vazgeç"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Hesabımı Sil"),
            ),
          ],
        );
      },
    );

    // If user cancelled, stop here
    if (confirm != true) return;

    // 2. Perform Deletion
    try {
      if (!mounted) return;

      // Show loading
      AlertService.showTopAlert(
        context,
        'Hesap siliniyor...',
        isError: false,
      );

      // Call the API (Make sure deleteAccount is added to ApiService as discussed)
      await ApiService.deleteAccount();

      // 3. Clear Local Data & Logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears token, user info, cart, etc.

      if (!mounted) return;

      setState(() {
        widget.initialUserData?.clear();
      });

      // Navigate to EntryPoint or Login to reset state
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      AlertService.showTopAlert(
        context,
        'Hesabınız başarıyla silindi.',
        isError: false,
      );

    } catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(
        context,
        e.toString().replaceAll("Exception: ", ""),
        isError: true,
      );
    }
  }

  // ---------- UI helpers ----------
  Widget _sectionTitle(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.textTheme.bodyMedium?.color,
          letterSpacing: .2,
        ),
      ),
    );
  }

  /// ✅ FIX: Smart Background Color for Dark Mode
  BoxDecoration _cardDec(BuildContext context, {bool white = false}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Color backgroundColor;

    if (white) {
      // High contrast dark grey for dark mode, pure white for light mode
      backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    } else {
      backgroundColor = theme.cardColor;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
    );
  }

  /// ✅ FIX: High Contrast Text & Icons
  Widget _actionTile(
      IconData icon,
      String title, {
        VoidCallback? onTap,
        Color? iconBg,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Force White text in Dark Mode
    final textColor = isDark ? Colors.white : theme.textTheme.bodyMedium?.color;
    final iconColor = isDark ? Colors.white70 : theme.iconTheme.color;
    final arrowColor = isDark ? Colors.white54 : theme.iconTheme.color;

    return Container(
      decoration: _cardDec(context, white: true),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2, horizontal: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: (iconBg ?? primaryColor.withOpacity(isDark ? 0.25 : 0.12)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor, // ✅ High Contrast
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: arrowColor),
        onTap: onTap,
      ),
    );
  }

  /// ✅ FIX: Header visibility
  Widget _profileHeader({
    required bool isLoggedIn,
    required String displayName,
    required String? email,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameColor = isDark ? Colors.white : theme.textTheme.bodyMedium?.color;
    final emailColor = isDark ? Colors.grey[400] : theme.textTheme.bodyMedium?.color?.withOpacity(0.8);
    final iconColor = isDark ? Colors.white : theme.iconTheme.color;

    return Container(
      decoration: _cardDec(context, white: true),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: primaryColor.withOpacity(isDark ? 0.25 : 0.12),
            child: Icon(Icons.person, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: nameColor, // ✅ High Contrast Name
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn ? (email ?? '') : "Henüz giriş yapmadınız",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: emailColor, // ✅ Light Grey Email
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isLoggedIn)
            IconButton(
              tooltip: "Bilgilerini Düzenle",
              icon: Icon(Icons.edit, size: 18, color: iconColor),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<String?>(
      future: _getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: const Center(child: ProfileSkeleton()),
          );
        }

        final token = snapshot.data;

        if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
          return FutureBuilder<Map<String, dynamic>>(
            future: ApiService.fetchUserInfo(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: const Center(child: ProfileSkeleton()),
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
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : theme.textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _profileHeader(isLoggedIn: isLoggedIn, displayName: displayName, email: email),
          const SizedBox(height: 8),

          if (!isLoggedIn) ...[
            _sectionTitle("Hızlı İşlemler"),
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    Icons.login,
                    'Giriş Yap',
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    iconBg: Colors.green.withOpacity(0.12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionTile(
                    Icons.person_add,
                    'Kayıt Ol',
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    iconBg: Colors.blue.withOpacity(0.12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _actionTile(
              Icons.favorite_border,
              'İstek Listem',
              onTap: () => Navigator.pushNamed(context, '/wishlist'),
            ),
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
            _actionTile(
              Icons.favorite_border,
              'İstek Listem',
              onTap: () => Navigator.pushNamed(context, '/wishlist'),
            ),
          ],

          _sectionTitle("Tercihler"),
          // Currency
          Container(
            decoration: _cardDec(context, white: true),
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange.withOpacity(isDark ? 0.25 : 0.12),
                  child: Icon(Icons.attach_money, size: 18, color: isDark ? Colors.white : theme.iconTheme.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Para Birimi',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isDense: true,
                    dropdownColor: theme.cardColor,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: (c) => c == null ? null : _updateCurrency(c),
                  ),
                ),
              ],
            ),
          ),

          // Dark mode
          Container(
            decoration: _cardDec(context, white: true),
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: SwitchListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2, horizontal: -2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              secondary: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.purple.withOpacity(isDark ? 0.25 : 0.12),
                child: Icon(Icons.brightness_6, size: 18, color: isDark ? Colors.white : theme.iconTheme.color),
              ),
              title: Text(
                'Karanlık Mod',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              value: theme.brightness == Brightness.dark,
              onChanged: (_) => MyApp.of(context)?.toggleTheme(),
            ),
          ),

          _sectionTitle("Diğer"),
          _actionTile(
            Icons.info_outline,
            'Hakkımızda',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HakkimizdaScreen(onLocaleChange: (_) {}),
                ),
              );
            },
          ),

          // ✅ Sıkça Sorulan Sorular
          _actionTile(
            Icons.help_outline,
            'Sıkça Sorulan Sorular',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FAQScreen(),
                ),
              );
            },
          ),

          // ✅ Gizlilik ve Güvenlik
          _actionTile(
            Icons.privacy_tip_outlined,
            'Gizlilik ve Güvenlik',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),

          // ✅ Kullanıcı Sözleşmesi
          _actionTile(
            Icons.description_outlined,
            'Kullanıcı Sözleşmesi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),

          if (isLoggedIn)
            _actionTile(
              Icons.logout,
              'Çıkış Yap',
              onTap: _logout,
              iconBg: Colors.red.withOpacity(isDark ? 0.25 : 0.12),
            ),

          // ✅ DELETE ACCOUNT BUTTON (Required for App Store)
          if (isLoggedIn) ...[
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: _deleteAccount,
                icon: Icon(Icons.delete_forever, color: Colors.red.withOpacity(0.8), size: 20),
                label: Text(
                  "Hesabımı Sil",
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.red.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}