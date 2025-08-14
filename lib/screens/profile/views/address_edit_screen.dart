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
  final TextEditingController _citySearch = TextEditingController();

  String? _selectedCityCode; // e.g. TR34
  bool _loading = true;
  bool _saving = false;

  // error flags for red borders
  bool _addrInvalid = false;
  bool _postcodeInvalid = false;
  bool _cityInvalid = false;

  final Map<String, String> _turkishCities = const {
    'Adana': 'TR01','Adıyaman':'TR02','Afyonkarahisar':'TR03','Ağrı':'TR04','Amasya':'TR05','Ankara':'TR06','Antalya':'TR07','Artvin':'TR08','Aydın':'TR09','Balıkesir':'TR10','Bilecik':'TR11','Bingöl':'TR12','Bitlis':'TR13','Bolu':'TR14','Burdur':'TR15','Bursa':'TR16','Çanakkale':'TR17','Çankırı':'TR18','Çorum':'TR19','Denizli':'TR20','Diyarbakır':'TR21','Edirne':'TR22','Elazığ':'TR23','Erzincan':'TR24','Erzurum':'TR25','Eskişehir':'TR26','Gaziantep':'TR27','Giresun':'TR28','Gümüşhane':'TR29','Hakkari':'TR30','Hatay':'TR31','Isparta':'TR32','Mersin':'TR33','İstanbul':'TR34','İzmir':'TR35','Kars':'TR36','Kastamonu':'TR37','Kayseri':'TR38','Kırklareli':'TR39','Kırşehir':'TR40','Kocaeli':'TR41','Konya':'TR42','Kütahya':'TR43','Malatya':'TR44','Manisa':'TR45','Kahramanmaraş':'TR46','Mardin':'TR47','Muğla':'TR48','Muş':'TR49','Nevşehir':'TR50','Niğde':'TR51','Ordu':'TR52','Rize':'TR53','Sakarya':'TR54','Samsun':'TR55','Siirt':'TR56','Sinop':'TR57','Sivas':'TR58','Tekirdağ':'TR59','Tokat':'TR60','Trabzon':'TR61','Tunceli':'TR62','Şanlıurfa':'TR63','Uşak':'TR64','Van':'TR65','Yozgat':'TR66','Zonguldak':'TR67','Aksaray':'TR68','Bayburt':'TR69','Karaman':'TR70','Kırıkkale':'TR71','Batman':'TR72','Şırnak':'TR73','Bartın':'TR74','Ardahan':'TR75','Iğdır':'TR76','Yalova':'TR77','Karabük':'TR78','Kilis':'TR79','Osmaniye':'TR80','Düzce':'TR81',
  };

  InputDecoration _dec(BuildContext context, String label, {bool isError = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseBorderColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isError ? Colors.red : baseBorderColor;

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
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: isError ? Colors.red : primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    );
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();

    // Clear red borders as the user types
    _address1.addListener(() {
      if (_addrInvalid && _address1.text.trim().isNotEmpty) {
        setState(() => _addrInvalid = false);
      }
    });
    _postcode.addListener(() {
      if (_postcodeInvalid && _postcode.text.trim().isNotEmpty) {
        setState(() => _postcodeInvalid = false);
      }
    });
  }

  @override
  void dispose() {
    _address1.dispose();
    _postcode.dispose();
    _citySearch.dispose();
    super.dispose();
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

  bool _validateAndAlert() {
    setState(() {
      _addrInvalid = _address1.text.trim().isEmpty;
      _postcodeInvalid = _postcode.text.trim().isEmpty;
      _cityInvalid = _selectedCityCode == null || _selectedCityCode!.isEmpty;
    });

    if (_addrInvalid) {
      AlertService.showTopAlert(context, "Lütfen adres satırını giriniz.", isError: true);
      return false;
    }
    if (_cityInvalid) {
      AlertService.showTopAlert(context, "Lütfen şehir seçiniz.", isError: true);
      return false;
    }
    if (_postcodeInvalid) {
      AlertService.showTopAlert(context, "Lütfen posta kodunu giriniz.", isError: true);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validateAndAlert()) return;

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

  Future<void> _openCityPicker() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Prepare initial list
    var entries = _turkishCities.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _citySearch
      ..text = ''
      ..selection = const TextSelection.collapsed(offset: 0);

    final selected = await showModalBottomSheet<MapEntry<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        List<MapEntry<String, String>> filtered = List.of(entries);

        void doFilter(String q) {
          final query = q.trim().toLowerCase();
          filtered = entries
              .where((e) => e.key.toLowerCase().contains(query))
              .toList();
          (ctx as Element).markNeedsBuild();
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              TextField(
                controller: _citySearch,
                decoration: InputDecoration(
                  hintText: "Şehir ara...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: doFilter,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: Scrollbar(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: theme.dividerColor.withOpacity(0.25)),
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            e.key,
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          ),
                          onTap: () => Navigator.pop(ctx, e),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (selected != null) {
      setState(() {
        _selectedCityCode = selected.value; // code like TR34
        _cityInvalid = false;               // clear red border
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: primaryColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: const Text(
          "Adresimi Düzenle",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Address
            TextField(
              controller: _address1,
              maxLines: 3,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
              decoration: _dec(context, "Adres Satırı *", isError: _addrInvalid)
                  .copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 14),

            // City (searchable picker styled like a field)
            InkWell(
              onTap: _openCityPicker,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _dec(context, "Şehir *", isError: _cityInvalid),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCityCode == null
                            ? "Bir şehir seçin"
                            : _turkishCities.entries
                            .firstWhere((e) => e.value == _selectedCityCode!)
                            .key,
                        style: TextStyle(
                          color: _selectedCityCode == null
                              ? theme.hintColor
                              : theme.textTheme.bodyMedium?.color,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Postcode
            TextField(
              controller: _postcode,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
              decoration: _dec(context, "Posta Kodu *", isError: _postcodeInvalid),
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
