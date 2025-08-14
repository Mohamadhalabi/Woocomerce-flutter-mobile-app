import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants.dart';
import '../../../services/alert_service.dart';
import '../../../services/api_service.dart';
import '../../order/views/order_succesfull_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems; // ✅ Required

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // We keep the form key but we won't rely on validator-borders anymore.
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // City search
  final TextEditingController _citySearchController = TextEditingController();

  String selectedCity = "";
  bool _cityInvalid = false; // ✅ controls red border for city when empty

  // Per-field error flags to control red borders
  bool _firstNameInvalid = false;
  bool _lastNameInvalid  = false;
  bool _addressInvalid   = false;
  bool _postcodeInvalid  = false;
  bool _districtInvalid  = false;
  bool _phoneInvalid     = false;
  bool _emailInvalid     = false;

  double subtotal = 0.0;
  double kdv = 0.0;
  double total = 0.0;

  // NOTE: trStateMap must be defined in your constants.dart as before
  late final List<String> turkishCities =
  trStateMap.values.toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    loadUserData();
    calculateTotals();

    // Clear error flags as soon as user types
    firstNameController.addListener(() {
      if (_firstNameInvalid && firstNameController.text.trim().isNotEmpty) {
        setState(() => _firstNameInvalid = false);
      }
    });
    lastNameController.addListener(() {
      if (_lastNameInvalid && lastNameController.text.trim().isNotEmpty) {
        setState(() => _lastNameInvalid = false);
      }
    });
    addressController.addListener(() {
      if (_addressInvalid && addressController.text.trim().isNotEmpty) {
        setState(() => _addressInvalid = false);
      }
    });
    postcodeController.addListener(() {
      if (_postcodeInvalid && postcodeController.text.trim().isNotEmpty) {
        setState(() => _postcodeInvalid = false);
      }
    });
    districtController.addListener(() {
      final hasText = districtController.text.trim().isNotEmpty;
      if (_districtInvalid && hasText) {
        setState(() {
          _districtInvalid = false;
        });
      }
    });
    phoneController.addListener(() {
      if (_phoneInvalid && phoneController.text.trim().isNotEmpty) {
        setState(() => _phoneInvalid = false);
      }
    });
    emailController.addListener(() {
      if (_emailInvalid && emailController.text.trim().isNotEmpty) {
        setState(() => _emailInvalid = false);
      }
    });
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    postcodeController.dispose();
    districtController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String billingState = prefs.getString("billing_state") ?? "";
    String billingCity = prefs.getString("billing_city") ?? "";

    setState(() {
      firstNameController.text = prefs.getString("billing_first_name") ?? "";
      lastNameController.text = prefs.getString("billing_last_name") ?? "";
      addressController.text = prefs.getString("billing_address_1") ?? "";
      postcodeController.text = prefs.getString("billing_postcode") ?? "";
      phoneController.text = prefs.getString("billing_phone") ?? "";
      emailController.text = prefs.getString("billing_email") ?? "";
      districtController.text = billingCity;

      if (billingState.isNotEmpty && trStateMap.containsKey(billingState)) {
        selectedCity = trStateMap[billingState]!;
      }
    });
  }

  void calculateTotals() {
    double sub = 0.0;
    for (var item in widget.cartItems) {
      double price = 0.0;
      if (item['price'] is num) {
        price = (item['price'] as num).toDouble();
      } else if (item['price'] is String) {
        price = double.tryParse(item['price']) ?? 0.0;
      }
      final qty = int.tryParse(item['quantity'].toString()) ?? 1;
      sub += price * qty;
    }

    setState(() {
      subtotal = sub;
      kdv = subtotal * 0.20;
      total = subtotal + kdv;
    });
  }

  InputDecoration _inputDecoration(String label, ThemeData theme, {bool isError = false}) {
    final baseColor = theme.brightness == Brightness.dark ? Colors.white54 : Colors.grey.shade400;
    final borderColor = isError ? Colors.red : baseColor;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      errorStyle: const TextStyle(height: 0, fontSize: 0), // hide error text
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isError ? Colors.red : blueColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  // Helper: a consistent bordered card that adapts to light/dark
  Widget _borderedCard({
    required ThemeData theme,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry? margin,
  }) {
    final isLight = theme.brightness == Brightness.light;
    return Card(
      elevation: 0,
      color: isLight ? Colors.white : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
          width: 1,
        ),
      ),
      margin: margin,
      child: Padding(padding: padding, child: child),
    );
  }

  Future<void> _openCityPicker(ThemeData theme) async {
    // Start filtered list from all cities
    List<String> filtered = List.of(turkishCities);

    _citySearchController
      ..text = ''
      ..selection = const TextSelection.collapsed(offset: 0);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
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
              // Search field
              TextField(
                controller: _citySearchController,
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
                onChanged: (q) {
                  final query = q.trim().toLowerCase();
                  filtered = turkishCities.where((c) => c.toLowerCase().contains(query)).toList();
                  (ctx as Element).markNeedsBuild(); // rebuild bottom sheet
                },
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: Scrollbar(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (_, i) {
                        final city = filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(city),
                          onTap: () {
                            Navigator.pop(context, city);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.3),
                      ),
                      itemCount: filtered.length,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).then((value) {
      if (value is String && value.isNotEmpty) {
        setState(() {
          selectedCity = value;
          _cityInvalid = false; // clear error state if any
        });
      }
    });
  }

  /// Validates all inputs.
  /// - Sets red border flags.
  /// - Shows an AlertService message for the *first* missing field (clean UX).
  /// Returns true when all fields are valid.
  bool _validateAllAndAlert(BuildContext context) {
    final missing = <String>[];

    setState(() {
      _firstNameInvalid = firstNameController.text.trim().isEmpty;
      _lastNameInvalid  = lastNameController.text.trim().isEmpty;
      _addressInvalid   = addressController.text.trim().isEmpty;
      _postcodeInvalid  = postcodeController.text.trim().isEmpty;
      _districtInvalid  = districtController.text.trim().isEmpty;
      _phoneInvalid     = phoneController.text.trim().isEmpty;
      _emailInvalid     = emailController.text.trim().isEmpty;
      _cityInvalid      = selectedCity.isEmpty;
    });

    // Collect missing with their flag setters (for future extensibility)
    if (_firstNameInvalid) missing.add("Lütfen adınızı giriniz.");
    if (_lastNameInvalid)  missing.add("Lütfen soyadınızı giriniz.");
    if (_addressInvalid)   missing.add("Lütfen sokak adresini giriniz.");
    if (_postcodeInvalid)  missing.add("Lütfen posta kodunu giriniz.");
    if (_districtInvalid)  missing.add("Lütfen ilçe/semt bilgisini giriniz.");
    if (_cityInvalid)      missing.add("Lütfen şehir seçiniz.");
    if (_phoneInvalid)     missing.add("Lütfen telefon numarasını giriniz.");
    if (_emailInvalid)     missing.add("Lütfen e-posta adresini giriniz.");

    if (missing.isNotEmpty) {
      AlertService.showTopAlert(context, missing.first, isError: true);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ödeme', style: TextStyle(color: Colors.white)),
        backgroundColor: blueColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: theme.cardColor,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: blueColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            // Validate all inputs + alert for the first missing one
            if (!_validateAllAndAlert(context)) return;

            try {
              final stateCode = trStateMap.entries.firstWhere((e) => e.value == selectedCity).key;

              final billing = {
                "first_name": firstNameController.text.trim(),
                "last_name": lastNameController.text.trim(),
                "address_1": addressController.text.trim(),
                "city": districtController.text.trim(),
                "state": stateCode,
                "postcode": postcodeController.text.trim(),
                "country": "TR",
                "email": emailController.text.trim(),
                "phone": phoneController.text.trim(),
              };

              final shipping = billing;

              // ✅ Pass full cartItems to API so correct TRY price is sent
              final order = await ApiService.createOrder(
                billing: billing,
                shipping: shipping,
                cartItems: widget.cartItems,
              );

              AlertService.showTopAlert(
                context,
                "Sipariş başarıyla oluşturuldu (#${order['id']})",
                isError: false,
              );

              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderSuccessScreen(orderId: order['id']),
                ),
              );
            } catch (e) {
              AlertService.showTopAlert(context, e.toString(), isError: true);
            }
          },
          child: const Text(
            "Siparişi Onayla",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // BILLING FORM (bordered, adaptive)
              _borderedCard(
                theme: theme,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameController,
                            decoration: _inputDecoration("Ad", theme, isError: _firstNameInvalid),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameController,
                            decoration: _inputDecoration("Soyad", theme, isError: _lastNameInvalid),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: _inputDecoration("Sokak Adresi", theme, isError: _addressInvalid),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: postcodeController,
                      decoration: _inputDecoration("Posta Kodu", theme, isError: _postcodeInvalid),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: districtController,
                      decoration: _inputDecoration("İlçe / Semt", theme, isError: _districtInvalid),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Searchable "dropdown" for City with red border when empty
                    InkWell(
                      onTap: () => _openCityPicker(theme),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _inputDecoration("Şehir", theme, isError: _cityInvalid),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedCity.isNotEmpty ? selectedCity : "Bir şehir seçin",
                                style: TextStyle(
                                  color: selectedCity.isNotEmpty
                                      ? theme.textTheme.bodyMedium?.color
                                      : theme.hintColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: _inputDecoration("Telefon", theme, isError: _phoneInvalid),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: _inputDecoration("E-posta", theme, isError: _emailInvalid),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CART SUMMARY (Sepet Özeti) — bordered, adaptive
              _borderedCard(
                theme: theme,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sepet Özeti",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...widget.cartItems.map(
                          (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item['image'] ?? '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                const Icon(Icons.image_not_supported, size: 40),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${item['title'] ?? 'Ürün'} x${item['quantity']}",
                                style: const TextStyle(fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "₺${(((item['price'] ?? 0) as num).toDouble() * (int.tryParse(item['quantity'].toString()) ?? 1)).toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    _summaryRow("Ara Toplam", subtotal),
                    _summaryRow("KDV (%20)", kdv),
                    _summaryRow("Toplam", total, isTotal: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            "₺${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? blueColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
