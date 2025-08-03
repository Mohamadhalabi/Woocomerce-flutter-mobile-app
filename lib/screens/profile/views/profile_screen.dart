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

    // Clear any stored user data immediately
    setState(() {
      widget.initialUserData?.clear();
    });

    AlertService.showTopAlert(
      context,
      'Başarıyla çıkış yapıldı',
      isError: false,
    );
  }

  /// Edit Profile Modal
  void _openEditProfileModal(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final firstNameController =
    TextEditingController(text: user['first_name'] ?? '');
    final lastNameController =
    TextEditingController(text: user['last_name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final passwordController = TextEditingController();

    print(user);

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        InputDecoration _inputDecoration(String label) {
          return InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[700],
            ),
            filled: true,
            fillColor: theme.brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Bilgilerini Düzenle",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: firstNameController,
                        decoration: _inputDecoration("Ad *"),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: lastNameController,
                        decoration: _inputDecoration("Soyad *"),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailController,
                        decoration: _inputDecoration("E-posta"),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: phoneController,
                        decoration: _inputDecoration("Telefon *"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: _inputDecoration("Şifre (Opsiyonel)"),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("İptal"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                // ✅ Validation
                                if (firstNameController.text.trim().isEmpty) {
                                  AlertService.showTopAlert(context, "Ad boş olamaz", isError: true);
                                  return;
                                }
                                if (lastNameController.text.trim().isEmpty) {
                                  AlertService.showTopAlert(context, "Soyad boş olamaz", isError: true);
                                  return;
                                }
                                if (phoneController.text.trim().isEmpty) {
                                  AlertService.showTopAlert(context, "Telefon boş olamaz", isError: true);
                                  return;
                                }

                                setState(() => isSaving = true);
                                try {
                                  // 1️⃣ Update profile in WooCommerce
                                  await ApiService.updateUserProfile(
                                    firstName: firstNameController.text.trim(),
                                    lastName: lastNameController.text.trim(),
                                    email: emailController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    password: passwordController.text.trim().isEmpty
                                        ? null
                                        : passwordController.text.trim(),
                                  );

                                  // 2️⃣ Fetch updated data from API immediately
                                  final updatedUser = await ApiService.fetchUserInfo();

                                  // 3️⃣ Update initialUserData so UI refreshes instantly
                                  setState(() {
                                    widget.initialUserData?.clear();
                                    widget.initialUserData?.addAll(updatedUser);
                                  });

                                  if (!mounted) return;
                                  Navigator.pop(context);

                                  // 4️⃣ Show success message
                                  AlertService.showTopAlert(context, 'Profil güncellendi', isError: false);

                                  // 5️⃣ Refresh profile view
                                  refresh();
                                } catch (e) {
                                  AlertService.showTopAlert(context, e.toString(), isError: true);
                                } finally {
                                  setState(() => isSaving = false);
                                }
                              },
                              child: isSaving
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                                  : const Text("Kaydet"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Edit Address Modal
  /// Turkish city map
  final Map<String, String> _turkishCities = {
    'Adana': 'TR01',
    'Adıyaman': 'TR02',
    'Afyonkarahisar': 'TR03',
    'Ağrı': 'TR04',
    'Amasya': 'TR05',
    'Ankara': 'TR06',
    'Antalya': 'TR07',
    'Artvin': 'TR08',
    'Aydın': 'TR09',
    'Balıkesir': 'TR10',
    'Bilecik': 'TR11',
    'Bingöl': 'TR12',
    'Bitlis': 'TR13',
    'Bolu': 'TR14',
    'Burdur': 'TR15',
    'Bursa': 'TR16',
    'Çanakkale': 'TR17',
    'Çankırı': 'TR18',
    'Çorum': 'TR19',
    'Denizli': 'TR20',
    'Diyarbakır': 'TR21',
    'Edirne': 'TR22',
    'Elazığ': 'TR23',
    'Erzincan': 'TR24',
    'Erzurum': 'TR25',
    'Eskişehir': 'TR26',
    'Gaziantep': 'TR27',
    'Giresun': 'TR28',
    'Gümüşhane': 'TR29',
    'Hakkari': 'TR30',
    'Hatay': 'TR31',
    'Isparta': 'TR32',
    'Mersin': 'TR33',
    'İstanbul': 'TR34',
    'İzmir': 'TR35',
    'Kars': 'TR36',
    'Kastamonu': 'TR37',
    'Kayseri': 'TR38',
    'Kırklareli': 'TR39',
    'Kırşehir': 'TR40',
    'Kocaeli': 'TR41',
    'Konya': 'TR42',
    'Kütahya': 'TR43',
    'Malatya': 'TR44',
    'Manisa': 'TR45',
    'Kahramanmaraş': 'TR46',
    'Mardin': 'TR47',
    'Muğla': 'TR48',
    'Muş': 'TR49',
    'Nevşehir': 'TR50',
    'Niğde': 'TR51',
    'Ordu': 'TR52',
    'Rize': 'TR53',
    'Sakarya': 'TR54',
    'Samsun': 'TR55',
    'Siirt': 'TR56',
    'Sinop': 'TR57',
    'Sivas': 'TR58',
    'Tekirdağ': 'TR59',
    'Tokat': 'TR60',
    'Trabzon': 'TR61',
    'Tunceli': 'TR62',
    'Şanlıurfa': 'TR63',
    'Uşak': 'TR64',
    'Van': 'TR65',
    'Yozgat': 'TR66',
    'Zonguldak': 'TR67',
    'Aksaray': 'TR68',
    'Bayburt': 'TR69',
    'Karaman': 'TR70',
    'Kırıkkale': 'TR71',
    'Batman': 'TR72',
    'Şırnak': 'TR73',
    'Bartın': 'TR74',
    'Ardahan': 'TR75',
    'Iğdır': 'TR76',
    'Yalova': 'TR77',
    'Karabük': 'TR78',
    'Kilis': 'TR79',
    'Osmaniye': 'TR80',
    'Düzce': 'TR81',
  };

  Future<void> _openEditAddressModal(Map<String, dynamic> user) async {
    Map<String, dynamic> latestBilling = {};
    String? selectedCityCode;

    try {
      final prefs = await SharedPreferences.getInstance();
      final billingData = await ApiService.fetchUserBilling();

      if (billingData['billing'] != null) {
        latestBilling = billingData['billing'];

        // Match city code from stored state or city name
        selectedCityCode = latestBilling['state']?.isNotEmpty == true
            ? latestBilling['state']
            : _turkishCities[latestBilling['city'] ?? ''];

        await prefs.setString('billing_city', latestBilling['city'] ?? '');
        await prefs.setString('billing_state', selectedCityCode ?? '');
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch billing info: $e");
    }

    final theme = Theme.of(context);
    final address1Controller = TextEditingController(text: latestBilling['address_1'] ?? '');
    final postcodeController = TextEditingController(text: latestBilling['postcode'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text("Adresimi Düzenle",
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      // Address
                      TextField(
                        controller: address1Controller,
                        maxLines: 3, // like a textarea height
                        textAlignVertical: TextAlignVertical.top, // start from top
                        decoration: InputDecoration(
                          labelText: "Adres Satırı *",
                          alignLabelWithHint: true, // keep label aligned when multi-line
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Turkish City Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedCityCode,
                        decoration: InputDecoration(labelText: "Şehir *"),
                        items: _turkishCities.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.value,
                            child: Text(entry.key),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedCityCode = value);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Postcode
                      TextField(
                        controller: postcodeController,
                        decoration: InputDecoration(labelText: "Posta Kodu *"),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("İptal"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                if (address1Controller.text.trim().isEmpty ||
                                    selectedCityCode == null ||
                                    postcodeController.text.trim().isEmpty) {
                                  AlertService.showTopAlert(
                                      context, "Lütfen gerekli alanları doldurun", isError: true);
                                  return;
                                }

                                setState(() => isSaving = true);
                                try {
                                  await ApiService.updateUserAddress(
                                    address1: address1Controller.text.trim(),
                                    city: _turkishCities.entries
                                        .firstWhere((e) => e.value == selectedCityCode)
                                        .key,
                                    state: selectedCityCode!, // send TR code
                                    postcode: postcodeController.text.trim(),
                                  );
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  AlertService.showTopAlert(context, 'Adres güncellendi', isError: false);
                                  refresh();
                                } catch (e) {
                                  AlertService.showTopAlert(context, e.toString(), isError: true);
                                } finally {
                                  setState(() => isSaving = false);
                                }
                              },
                              child: isSaving
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Text("Kaydet"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              title: Text(displayName,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
              subtitle: isLoggedIn
                  ? Text(email,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12))
                  : Text("Henüz giriş yapmadınız",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: isLoggedIn
                  ? IconButton(
                icon: Icon(Icons.edit, size: 20, color: Theme.of(context).iconTheme.color),
                onPressed: () => _openEditProfileModal(user!),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (!isLoggedIn) ...[
            Row(
              children: [
                Expanded(child: _cardItem(Icons.login, 'Giriş Yap', onTap: () => Navigator.pushNamed(context, '/login'))),
                const SizedBox(width: 8),
                Expanded(child: _cardItem(Icons.person_add, 'Kayıt Ol', onTap: () => Navigator.pushNamed(context, '/register'))),
              ],
            ),
            const SizedBox(height: 8),
            _cardItem(Icons.favorite_border, 'İstek Listem', onTap: () => Navigator.pushNamed(context, '/wishlist')),
          ],
          if (isLoggedIn) ...[
            _cardItem(Icons.location_on, 'Adresim', onTap: () => _openEditAddressModal(user!)),
            _cardItem(Icons.list_alt, 'Siparişlerim', onTap: () {
              Navigator.pushNamed(context, '/orders');
            }),
            _cardItem(Icons.favorite_border, 'İstek Listem', onTap: () => Navigator.pushNamed(context, '/wishlist')),
          ],
          _buildCurrencySelector(),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: SwitchListTile(
              secondary: Icon(Icons.brightness_6, color: Theme.of(context).iconTheme.color),
              title: Text('Karanlık Mod', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (val) => MyApp.of(context)?.toggleTheme(),
            ),
          ),
          _cardItem(Icons.info_outline, 'Hakkımızda', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HakkimizdaScreen(onLocaleChange: (_) {}),
              ),
            );
          }),
          if (isLoggedIn) _cardItem(Icons.logout, 'Çıkış Yap', onTap: _logout),
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
            return DropdownMenuItem(value: currency, child: Text(currency));
          }).toList(),
          onChanged: (newCurrency) {
            if (newCurrency != null) _updateCurrency(newCurrency);
          },
        ),
      ),
    );
  }

  Future<void> refresh() async {
    setState(() {});
  }
}