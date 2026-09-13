import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/profile/views/privacy_policy_screen.dart';
import 'package:shop/screens/profile/views/terms_of_service_screen.dart';
import '../../../services/alert_service.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/currency_provider.dart';
import '../../../main.dart';
import '../../about/hakkimizda_screen.dart';

import 'address_edit_screen_v2.dart';
import 'faq_screen.dart';
import '../../order/views/orders_screen_v2.dart';

import '../../../models/customer_model.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../../repositories/account_repository.dart';
import '../../../services/currency_service.dart';
import '../../../services/taxonomy_service.dart';

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
  String _selectedCurrency = CurrencyService.current;
  List<Currency> _currencies = const [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  /// The options come from GET /currencies, so adding a currency in the admin
  /// makes it appear here with no app release.
  Future<void> _loadCurrencies() async {
    final list = await CurrencyService.available();
    if (!mounted) return;
    setState(() {
      _currencies = list;
      _selectedCurrency = CurrencyService.current;
    });
  }

  Future<void> _updateCurrency(String newCurrency) async {
    // Sets the X-Currency header and clears cached prices. Without this the
    // choice was only written to SharedPreferences and the API kept returning
    // the old currency.
    final changed = await CurrencyService.set(newCurrency);
    if (!changed || !mounted) return;

    Provider.of<CurrencyProvider>(context, listen: false)
        .setCurrency(newCurrency);

    setState(() => _selectedCurrency = newCurrency);

    AlertService.showTopAlert(
      context,
      'Para birimi güncellendi: $newCurrency',
      isError: false,
    );
  }

  Future<void> _logout() async {
    // Revokes the token server-side, clears it locally, and drops the cart
    // token — the server cart now belongs to the customer.
    await authRepo.logout();

    // Prices and home sections are cached per audience, so the signed-in
    // copies have to go.
    await TaxonomyService.onAuthChanged();

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

  Future<void> _deleteAccount() async {
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

    if (confirm != true) return;

    try {
      if (!mounted) return;

      AlertService.showTopAlert(context, 'Hesap siliniyor...', isError: false);

      // NOTE: DELETE /auth/me doesn't exist on the API yet — this throws a 404
      // until the backend adds it. Required by the App Store and Play Store.
      await authRepo.deleteAccount();
      await TaxonomyService.onAuthChanged();

      if (!mounted) return;

      setState(() {
        widget.initialUserData?.clear();
      });

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      AlertService.showTopAlert(
        context,
        'Hesabınız başarıyla silindi.',
        isError: false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(context, e.message, isError: true);
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

  BoxDecoration _cardDec(BuildContext context, {bool white = false}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Color backgroundColor;

    if (white) {
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

  Widget _actionTile(
      IconData icon,
      String title, {
        VoidCallback? onTap,
        Color? iconBg,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          backgroundColor:
          (iconBg ?? primaryColor.withOpacity(isDark ? 0.25 : 0.12)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: arrowColor),
        onTap: onTap,
      ),
    );
  }

  Widget _profileHeader({
    required bool isLoggedIn,
    required String displayName,
    required String? email,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameColor = isDark ? Colors.white : theme.textTheme.bodyMedium?.color;
    final emailColor = isDark
        ? Colors.grey[400]
        : theme.textTheme.bodyMedium?.color?.withOpacity(0.8);
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
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn ? (email ?? '') : "Henüz giriş yapmadınız",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: emailColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // The edit button is hidden until EditProfileScreen is migrated —
          // it took the WooCommerce user map, and PATCH /auth/me expects a
          // different shape.
        ],
      ),
    );
  }
  // --------------------------------

  @override
  Widget build(BuildContext context) {
    // Sanctum tokens are opaque strings, not JWTs — there's nothing to decode,
    // and JwtDecoder threw FormatException on them. AuthRepository already
    // verified the session against /auth/me at startup and holds the customer.
    final customer = authRepo.customer;

    return _buildProfileView(
      isLoggedIn: customer != null,
      customer: customer,
    );
  }

  Widget _buildProfileView({
    required bool isLoggedIn,
    CustomerModel? customer,
  }) {
    final email = customer?.email ?? '';
    final displayName = isLoggedIn
        ? (customer!.name.trim().isNotEmpty ? customer.name : email)
        : 'Misafir Kullanıcı';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor =
    isDark ? Colors.white : theme.textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _profileHeader(
            isLoggedIn: isLoggedIn,
            displayName: displayName,
            email: email,
          ),
          const SizedBox(height: 8),

          // An approved account can see prices; an unapproved one can't, so
          // it's worth saying why rather than leaving them confused.
          if (isLoggedIn && !customer!.isApproved) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, size: 20, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hesabınız onay bekliyor. Onaylandıktan sonra '
                          'fiyatları görebilirsiniz.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!isLoggedIn) ...[
            _sectionTitle("Hızlı İşlemler"),
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    Icons.login,
                    'Giriş Yap',
                    onTap: () async {
                      await Navigator.pushNamed(context, '/login');
                      if (mounted) setState(() {});
                    },
                    iconBg: Colors.green.withOpacity(0.12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionTile(
                    Icons.person_add,
                    'Kayıt Ol',
                    onTap: () async {
                      await Navigator.pushNamed(context, '/register');
                      if (mounted) setState(() {});
                    },
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
                MaterialPageRoute(builder: (_) => const AddressEditScreenV2()),
              );
              if (result == true && mounted) setState(() {});
            }),
            _actionTile(Icons.list_alt, 'Siparişlerim', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreenV2()),
              );
            }),
            _actionTile(
              Icons.favorite_border,
              'İstek Listem',
              onTap: () => Navigator.pushNamed(context, '/wishlist'),
            ),
          ],

          _sectionTitle("Tercihler"),
          Container(
            decoration: _cardDec(context, white: true),
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                  Colors.orange.withOpacity(isDark ? 0.25 : 0.12),
                  child: Icon(Icons.attach_money,
                      size: 18,
                      color: isDark ? Colors.white : theme.iconTheme.color),
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
                    // Null until the list loads — a value that isn't among the
                    // items makes DropdownButton throw.
                    value: _currencies.any((c) => c.code == _selectedCurrency)
                        ? _selectedCurrency
                        : null,
                    isDense: true,
                    dropdownColor: theme.cardColor,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _currencies
                        .map((c) => DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code}  ${c.symbol}'),
                    ))
                        .toList(),
                    onChanged: (c) => c == null ? null : _updateCurrency(c),
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: _cardDec(context, white: true),
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: SwitchListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2, horizontal: -2),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              secondary: CircleAvatar(
                radius: 16,
                backgroundColor:
                Colors.purple.withOpacity(isDark ? 0.25 : 0.12),
                child: Icon(Icons.brightness_6,
                    size: 18,
                    color: isDark ? Colors.white : theme.iconTheme.color),
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
                  builder: (context) =>
                      HakkimizdaScreen(onLocaleChange: (_) {}),
                ),
              );
            },
          ),
          _actionTile(
            Icons.help_outline,
            'Sıkça Sorulan Sorular',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),
          _actionTile(
            Icons.privacy_tip_outlined,
            'Gizlilik ve Güvenlik',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          _actionTile(
            Icons.description_outlined,
            'Kullanıcı Sözleşmesi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen()),
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

          if (isLoggedIn) ...[
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: _deleteAccount,
                icon: Icon(Icons.delete_forever,
                    color: Colors.red.withOpacity(0.8), size: 20),
                label: Text(
                  "Hesabımı Sil",
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.red.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
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