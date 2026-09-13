// lib/screens/profile/views/address_edit_screen_v2.dart
//
// GET /account/address, PUT /account/address.
//
// ONE address per customer — the schema holds no more, so there's no list, no
// "add new", and no default flag.
//
// Country is deliberately absent: OrderController hardcodes billing_country to
// 'TR', so a picker here would be decorative.

import 'package:flutter/material.dart';

import '../../../components/skleton/app_skeletons.dart';
import '../../../constants.dart';
import '../../../constants/turkish_cities.dart';
import '../../../repositories/account_repository.dart';
import '../../../services/alert_service.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';

class AddressEditScreenV2 extends StatefulWidget {
  const AddressEditScreenV2({super.key});

  @override
  State<AddressEditScreenV2> createState() => _AddressEditScreenV2State();
}

class _AddressEditScreenV2State extends State<AddressEditScreenV2> {
  final _formKey = GlobalKey<FormState>();

  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();

  String? _city;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final address = await accountRepo.address();
      if (!mounted) return;

      _addressController.text = address.address ?? '';
      _stateController.text = address.state ?? '';
      _postcodeController.text = address.postcode ?? '';

      // Only kept when it matches the list exactly — imported WooCommerce
      // addresses may spell provinces differently.
      final stored = address.city?.trim();
      _city =
      (stored != null && turkishCities.contains(stored)) ? stored : null;

      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await accountRepo.updateAddress(AddressModel(
        address: _addressController.text.trim(),
        city: _city,
        state: _stateController.text.trim(),
        postcode: _postcodeController.text.trim(),
        country: 'TR',
      ));

      if (!mounted) return;
      AlertService.showTopAlert(context, 'Adresiniz güncellendi',
          isError: false);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCity(FormFieldState<String> field) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CityPickerSheet(selected: _city),
    );

    if (selected != null) {
      setState(() => _city = selected);
      field.didChange(selected);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder:
    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: primaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Adresim', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const FormSkeleton(fields: 4)
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _addressController,
              decoration: _decoration('Adres Satırı *'),
              maxLines: 3,
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Adres zorunludur'
                  : null,
            ),
            const SizedBox(height: 16),

            // Şehir and Posta Kodu share a row — the province name
            // is short, and a full-width control for it wastes the
            // form.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _cityField()),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _postcodeController,
                    decoration: _decoration('Posta Kodu'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _stateController,
              decoration: _decoration('İlçe'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A tap target styled as a form field. FormField keeps it inside the normal
  /// validation flow even though it isn't a TextField.
  Widget _cityField() {
    return FormField<String>(
      initialValue: _city,
      validator: (v) => (v == null || v.isEmpty) ? 'Şehir seçin' : null,
      builder: (field) {
        return InkWell(
          onTap: () => _pickCity(field),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _decoration('Şehir *').copyWith(
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
            ),
            isEmpty: _city == null,
            child: Text(
              _city ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        );
      },
    );
  }
}

/// Half-height sheet with a search box. A plain DropdownButton opens a menu
/// the full height of the screen and has no way to filter 81 entries.
class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({this.selected});

  final String? selected;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _results = turkishCities;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Turkish needs its own folding: the ASCII toLowerCase leaves İ and I
  /// wrong, so "Istanbul" wouldn't match "İstanbul".
  String _fold(String value) => value
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('â', 'a');

  void _search(String query) {
    final q = _fold(query.trim());
    setState(() {
      _results = q.isEmpty
          ? turkishCities
          : turkishCities.where((c) => _fold(c).contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        // Lifts the sheet above the keyboard when the search field has focus.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Şehir Seçin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                child: Text('Sonuç bulunamadı',
                    style: TextStyle(color: Colors.grey)),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final city = _results[i];
                  final isSelected = city == widget.selected;

                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    selected: isSelected,
                    selectedTileColor: primaryColor.withOpacity(0.08),
                    title: Text(
                      city,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check,
                        size: 18, color: primaryColor)
                        : null,
                    onTap: () => Navigator.pop(context, city),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}