import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants.dart';
import '../../../services/alert_service.dart';
import '../../../services/api_service.dart';
import '../../order/views/order_succesfull_screen.dart';
import '../../../modules/payment/iyzico_challenge_webview.dart';
import '../../../services/cart_service.dart';
import '../../order/views/order_failed_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems; // Required
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum PaymentMethod { transfer, iyzico }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Address controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController  = TextEditingController();
  final TextEditingController addressController   = TextEditingController();
  final TextEditingController postcodeController  = TextEditingController();
  final TextEditingController districtController  = TextEditingController();
  final TextEditingController phoneController     = TextEditingController();
  final TextEditingController emailController     = TextEditingController();

  // Card controllers (INLINE card form)
  final TextEditingController cardNameController   = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardMonthController  = TextEditingController();
  final TextEditingController cardYearController   = TextEditingController();
  final TextEditingController cardCvcController    = TextEditingController();

  // City search
  final TextEditingController _citySearchController = TextEditingController();
  late final List<String> turkishCities = trStateMap.values.toSet().toList()..sort();

  // Validation flags
  String selectedCity = "";
  bool _cityInvalid = false;
  bool _firstNameInvalid = false;
  bool _lastNameInvalid  = false;
  bool _addressInvalid   = false;
  bool _postcodeInvalid  = false;
  bool _districtInvalid  = false;
  bool _phoneInvalid     = false;
  bool _emailInvalid     = false;

  // Totals
  double subtotal = 0.0;
  double kdv = 0.0;
  double total = 0.0;

  // Payment state
  PaymentMethod _selectedMethod = PaymentMethod.transfer;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
    calculateTotals();

    // Clear flags as user types
    firstNameController.addListener(() { if (_firstNameInvalid && firstNameController.text.trim().isNotEmpty) setState(() => _firstNameInvalid = false); });
    lastNameController.addListener(() { if (_lastNameInvalid  && lastNameController.text.trim().isNotEmpty) setState(() => _lastNameInvalid  = false); });
    addressController.addListener(() { if (_addressInvalid   && addressController.text.trim().isNotEmpty)   setState(() => _addressInvalid   = false); });
    postcodeController.addListener(() { if (_postcodeInvalid  && postcodeController.text.trim().isNotEmpty)  setState(() => _postcodeInvalid  = false); });
    districtController.addListener(() { if (_districtInvalid  && districtController.text.trim().isNotEmpty)  setState(() => _districtInvalid  = false); });
    phoneController.addListener(() { if (_phoneInvalid     && phoneController.text.trim().isNotEmpty)     setState(() => _phoneInvalid     = false); });
    emailController.addListener(() { if (_emailInvalid     && emailController.text.trim().isNotEmpty)     setState(() => _emailInvalid     = false); });
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

    cardNameController.dispose();
    cardNumberController.dispose();
    cardMonthController.dispose();
    cardYearController.dispose();
    cardCvcController.dispose();

    super.dispose();
  }
  Future<void> _handleSuccessfulPayment(String orderIdStr) async {
    final orderId = int.tryParse(orderIdStr) ?? 0;

    // clear cart like transfer
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      await CartService.clearAll(token: token);
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
    );
  }

  void _goFailed([String? orderIdStr]) {
    final oid = int.tryParse(orderIdStr ?? '') ?? null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderFailedScreen(orderId: oid)),
    );
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final billingState = prefs.getString("billing_state") ?? "";
    final billingCity  = prefs.getString("billing_city") ?? "";

    setState(() {
      firstNameController.text = prefs.getString("billing_first_name") ?? "";
      lastNameController.text  = prefs.getString("billing_last_name") ?? "";
      addressController.text   = prefs.getString("billing_address_1") ?? "";
      postcodeController.text  = prefs.getString("billing_postcode") ?? "";
      phoneController.text     = prefs.getString("billing_phone") ?? "";
      emailController.text     = prefs.getString("billing_email") ?? "";
      districtController.text  = billingCity;

      // Pre-fill card holder
      cardNameController.text =
          "${firstNameController.text} ${lastNameController.text}".trim();

      if (billingState.isNotEmpty && trStateMap.containsKey(billingState)) {
        selectedCity = trStateMap[billingState]!;
      }
    });
  }

  void calculateTotals() {
    double sub = 0.0;
    for (final item in widget.cartItems) {
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
      kdv = subtotal * 0.20; // your app’s KDV
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
      errorStyle: const TextStyle(height: 0, fontSize: 0),
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
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  InputDecoration _cardDec(String label, ThemeData theme) =>
      _inputDecoration(label, theme);

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
        side: BorderSide(color: isLight ? Colors.grey.shade300 : Colors.grey.shade700, width: 1),
      ),
      margin: margin,
      child: Padding(padding: padding, child: child),
    );
  }

  Future<void> _openCityPicker(ThemeData theme) async {
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
            left: 16, right: 16, top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _citySearchController,
                decoration: InputDecoration(
                  hintText: "Şehir ara...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (q) {
                  final query = q.trim().toLowerCase();
                  filtered = turkishCities.where((c) => c.toLowerCase().contains(query)).toList();
                  (ctx as Element).markNeedsBuild();
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
                          onTap: () => Navigator.pop(context, city),
                        );
                      },
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
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
          _cityInvalid = false;
        });
      }
    });
  }

  bool _validateAllAndAlert(BuildContext context) {
    final missing = <String>[];

    final emailVal = emailController.text.trim();
    // Regex for email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    setState(() {
      _firstNameInvalid = firstNameController.text.trim().isEmpty;
      _lastNameInvalid  = lastNameController.text.trim().isEmpty;
      _addressInvalid   = addressController.text.trim().isEmpty;
      _postcodeInvalid  = postcodeController.text.trim().isEmpty;
      _districtInvalid  = districtController.text.trim().isEmpty;
      _phoneInvalid     = phoneController.text.trim().isEmpty;

      // Email validation: Check if empty OR if format is wrong
      _emailInvalid     = emailVal.isEmpty || !emailRegex.hasMatch(emailVal);

      _cityInvalid      = selectedCity.isEmpty;
    });

    if (_firstNameInvalid) missing.add("Lütfen adınızı giriniz.");
    if (_lastNameInvalid)  missing.add("Lütfen soyadınızı giriniz.");
    if (_addressInvalid)   missing.add("Lütfen sokak adresini giriniz.");
    if (_postcodeInvalid)  missing.add("Lütfen posta kodunu giriniz.");
    if (_districtInvalid)  missing.add("Lütfen ilçe/semt bilgisini giriniz.");
    if (_cityInvalid)      missing.add("Lütfen şehir seçiniz.");
    if (_phoneInvalid)     missing.add("Lütfen telefon numarasını giriniz.");

    // Updated error message for email
    if (_emailInvalid)     missing.add("Lütfen geçerli bir e-posta adresi giriniz.");

    if (missing.isNotEmpty) {
      AlertService.showTopAlert(context, missing.first, isError: true);
      return false;
    }
    return true;
  }

  Future<void> _payTransfer(Map<String, dynamic> billing) async {
    final order = await ApiService.createOrder(
      billing: billing,
      shipping: billing,
      cartItems: widget.cartItems,
    );
    if (!mounted) return;
    AlertService.showTopAlert(context, "Sipariş başarıyla oluşturuldu (#${order['id']})");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: order['id'])),
    );
  }

  // -------- INLINE iyzico payment (card form is on this screen) ----------
  Future<void> _payIyzicoInline(Map<String, dynamic> billing) async {
    String digits(String s) => s.replaceAll(RegExp(r'\D'), '');
    final numOk = digits(cardNumberController.text).length >= 12;
    final monOk = cardMonthController.text.trim().length >= 2;
    final yrOk  = cardYearController.text.trim().length >= 2;
    final cvcOk = cardCvcController.text.trim().length >= 3;

    if (!numOk || !monOk || !yrOk || !cvcOk) {
      AlertService.showTopAlert(context, "Kart bilgilerini kontrol edin.", isError: true);
      return;
    }

    final card = {
      'holder'  : cardNameController.text.trim().isEmpty
          ? "${billing['first_name']} ${billing['last_name']}".trim()
          : cardNameController.text.trim(),
      'number'  : digits(cardNumberController.text),
      'expMonth': cardMonthController.text.trim(),
      'expYear' : cardYearController.text.trim(), // 26 or 2026 are fine; backend normalizes
      'cvc'     : cardCvcController.text.trim(),
      'registerCard': false,
    };

    try {
      setState(() => _isPaying = true);

      // get logged-in user id (if any) to attach order on the server
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('user_id');

      final resp = await ApiService.payIyzicoCard(
        billing   : billing,
        cartItems : widget.cartItems,
        total     : total, // TRY total from this screen
        card      : card,
        use3ds    : true,
        customerId: customerId, // <-- important
      );

      final orderId = (resp['orderId'] ?? '').toString();

      // Direct success (no 3DS)
      if (resp['paid'] == true) {
        if (!mounted) return;
        await _handleSuccessfulPayment(orderId);
        return;
      }

      // 3DS path
      final html = (resp['threeDSHtml'] ?? '').toString();
      if (html.isEmpty) {
        // no html means init failed
        AlertService.showTopAlert(context, '3DS başlatılamadı.', isError: true);
        _goFailed(orderId);
        return;
      }

      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => IyzicoChallengeWebView(html: html, orderId: orderId),
        ),
      );

      if (!mounted) return;

      if (ok == true) {
        await _handleSuccessfulPayment(orderId);
      } else {
        _goFailed(orderId);
      }
    } catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(context, e.toString(), isError: true);
      _goFailed(); // unknown order id
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
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
          onPressed: _isPaying ? null : () async {
            if (!_validateAllAndAlert(context)) return;

            try {
              setState(() => _isPaying = true);

              final stateCode = trStateMap.entries.firstWhere((e) => e.value == selectedCity).key;
              final billing = {
                "first_name": firstNameController.text.trim(),
                "last_name":  lastNameController.text.trim(),
                "address_1":  addressController.text.trim(),
                "city":       districtController.text.trim(),
                "state":      stateCode,
                "postcode":   postcodeController.text.trim(),
                "country":    "TR",
                "email":      emailController.text.trim(),
                "phone":      phoneController.text.trim(),
              };

              if (_selectedMethod == PaymentMethod.transfer) {
                await _payTransfer(billing);
              } else {
                await _payIyzicoInline(billing);
              }
            } catch (e) {
              if (!mounted) return;
              AlertService.showTopAlert(context, e.toString(), isError: true);
            } finally {
              if (mounted) setState(() => _isPaying = false);
            }
          },
          child: Text(
            _isPaying ? "İşleniyor..." : "Siparişi Onayla",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // BILLING
              _borderedCard(
                theme: theme,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: firstNameController,
                          decoration: _inputDecoration("Ad", theme, isError: _firstNameInvalid),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(
                          controller: lastNameController,
                          decoration: _inputDecoration("Soyad", theme, isError: _lastNameInvalid),
                        )),
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

                    // City selector
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

              // PAYMENT METHOD (+ inline card form)
              _borderedCard(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ödeme Yöntemi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioListTile<PaymentMethod>(
                      value: PaymentMethod.transfer,
                      groupValue: _selectedMethod,
                      onChanged: (v) => setState(() => _selectedMethod = v!),
                      title: const Text("Havale / EFT (Banka Transferi)"),
                    ),
                    // RadioListTile<PaymentMethod>(
                    //   value: PaymentMethod.iyzico,
                    //   groupValue: _selectedMethod,
                    //   onChanged: (v) => setState(() => _selectedMethod = v!),
                    //   title: const Text("Kart ile Ödeme (iyzico)"),
                    // ),

                    if (_selectedMethod == PaymentMethod.iyzico) ...[
                      const SizedBox(height: 12),
                      Text("Kart Bilgileri", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cardNameController,
                        decoration: _cardDec("Kart Üzerindeki İsim", theme),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: _cardDec("Kart Numarası", theme),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(
                            controller: cardMonthController,
                            keyboardType: TextInputType.number,
                            decoration: _cardDec("Ay (MM)", theme),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(
                            controller: cardYearController,
                            keyboardType: TextInputType.number,
                            decoration: _cardDec("Yıl (YY / YYYY)", theme),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(
                            controller: cardCvcController,
                            keyboardType: TextInputType.number,
                            decoration: _cardDec("CVC", theme),
                          )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CART SUMMARY
              _borderedCard(
                theme: theme,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Sepet Özeti", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...widget.cartItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item['image'] ?? '',
                              width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 40),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            "${item['title'] ?? 'Ürün'} x${item['quantity']}",
                            style: const TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          )),
                          Text(
                            "₺${(((item['price'] ?? 0) as num).toDouble() * (int.tryParse(item['quantity'].toString()) ?? 1)).toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    )),
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
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
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