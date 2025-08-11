import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/constants.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/services/alert_service.dart';

class AddressEditScreen extends StatefulWidget {
  const AddressEditScreen({super.key});

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  final TextEditingController _address1 = TextEditingController();
  final TextEditingController _postcode = TextEditingController();
  String? _selectedCityCode;
  bool _loading = true;
  bool _saving = false;

  final Map<String, String> _turkishCities = const {
    'Adana': 'TR01','Adıyaman':'TR02','Afyonkarahisar':'TR03','Ağrı':'TR04','Amasya':'TR05','Ankara':'TR06','Antalya':'TR07','Artvin':'TR08','Aydın':'TR09','Balıkesir':'TR10','Bilecik':'TR11','Bingöl':'TR12','Bitlis':'TR13','Bolu':'TR14','Burdur':'TR15','Bursa':'TR16','Çanakkale':'TR17','Çankırı':'TR18','Çorum':'TR19','Denizli':'TR20','Diyarbakır':'TR21','Edirne':'TR22','Elazığ':'TR23','Erzincan':'TR24','Erzurum':'TR25','Eskişehir':'TR26','Gaziantep':'TR27','Giresun':'TR28','Gümüşhane':'TR29','Hakkari':'TR30','Hatay':'TR31','Isparta':'TR32','Mersin':'TR33','İstanbul':'TR34','İzmir':'TR35','Kars':'TR36','Kastamonu':'TR37','Kayseri':'TR38','Kırklareli':'TR39','Kırşehir':'TR40','Kocaeli':'TR41','Konya':'TR42','Kütahya':'TR43','Malatya':'TR44','Manisa':'TR45','Kahramanmaraş':'TR46','Mardin':'TR47','Muğla':'TR48','Muş':'TR49','Nevşehir':'TR50','Niğde':'TR51','Ordu':'TR52','Rize':'TR53','Sakarya':'TR54','Samsun':'TR55','Siirt':'TR56','Sinop':'TR57','Sivas':'TR58','Tekirdağ':'TR59','Tokat':'TR60','Trabzon':'TR61','Tunceli':'TR62','Şanlıurfa':'TR63','Uşak':'TR64','Van':'TR65','Yozgat':'TR66','Zonguldak':'TR67','Aksaray':'TR68','Bayburt':'TR69','Karaman':'TR70','Kırıkkale':'TR71','Batman':'TR72','Şırnak':'TR73','Bartın':'TR74','Ardahan':'TR75','Iğdır':'TR76','Yalova':'TR77','Karabük':'TR78','Kilis':'TR79','Osmaniye':'TR80','Düzce':'TR81',
  };

  InputDecoration _dec(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: labelColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    );
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final res = await ApiService.fetchUserBilling();
      final billing = (res['billing'] ?? {}) as Map<String, dynamic>;

      _address1.text = billing['address_1'] ?? '';
      _postcode.text = billing['postcode'] ?? '';

      final fromState = billing['state'];
      final fromCity = billing['city'];
      _selectedCityCode = (fromState is String && fromState.isNotEmpty)
          ? fromState
          : _turkishCities[fromCity ?? ''];
    } catch (_) {
      if (mounted) {
        AlertService.showTopAlert(context, "Adres bilgileri alınamadı", isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_address1.text.trim().isEmpty || _selectedCityCode == null || _postcode.text.trim().isEmpty) {
      AlertService.showTopAlert(context, "Lütfen gerekli alanları doldurun", isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final cityName = _turkishCities.entries.firstWhere((e) => e.value == _selectedCityCode!).key;

      await ApiService.updateUserAddress(
        address1: _address1.text.trim(),
        city: cityName,
        state: _selectedCityCode!,
        postcode: _postcode.text.trim(),
      );

      if (!mounted) return;
      AlertService.showTopAlert(context, "Adres güncellendi", isError: false);
      Navigator.pop(context, true);
    } catch (e) {
      AlertService.showTopAlert(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          // ensure correct status bar icons over primaryColor
          statusBarColor: primaryColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: const Text(
          "Adresimi Düzenle",
          style: TextStyle(fontSize: 16, color: Colors.white), // white title
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // makes back button white
        iconTheme: const IconThemeData(color: Colors.white), // back arrow white
      ),

      // adapt page background to theme
      backgroundColor: theme.scaffoldBackgroundColor,

      body: _loading
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _address1,
              maxLines: 3,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
              decoration: _dec(context, "Adres Satırı *").copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedCityCode,
              decoration: _dec(context, "Şehir *"),
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
              dropdownColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              items: _turkishCities.entries
                  .map((e) => DropdownMenuItem(
                value: e.value,
                child: Text(e.key, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCityCode = val),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _postcode,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
              decoration: _dec(context, "Posta Kodu *"),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.white30 : Colors.grey.shade400),
                      foregroundColor: theme.textTheme.bodyMedium?.color,
                    ),
                    child: const Text("İptal", style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Kaydet", style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
