// lib/screens/checkout/views/checkout_screen_v2.dart
//
// POST /orders.
//
// Body the API validates:
//   first_name*, last_name, email*, phone*, address*, city*, state, postcode,
//   payment_method* (havale|card), notes, terms* (must be accepted)
//
// Notes on the shape:
//   - There is NO separate shipping address. OrderController copies billing
//     into shipping, so collecting it twice would be theatre.
//   - Country is hardcoded 'TR' server-side, so there's no country picker.
//   - Totals are recomputed server-side from current prices. The figures here
//     are a preview only, and they duplicate three constants from
//     OrderController — see the note above _totals().

import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../constants/turkish_cities.dart';
import '../../../repositories/cart_repository.dart';
import '../../../services/alert_service.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../order/views/orders_screen_v2.dart';
import 'payment_webview_screen.dart';

class CheckoutScreenV2 extends StatefulWidget {
  const CheckoutScreenV2({super.key, required this.cart});

  final Cart cart;

  @override
  State<CheckoutScreenV2> createState() => _CheckoutScreenV2State();
}

enum PaymentMethod { havale, card }

class _CheckoutScreenV2State extends State<CheckoutScreenV2> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _notesController = TextEditingController();

  String? _city;
  PaymentMethod _method = PaymentMethod.havale;
  bool _terms = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Fills from the signed-in customer and their saved address, so a repeat
  /// order is a couple of taps.
  Future<void> _prefill() async {
    final customer = authRepo.customer;
    if (customer != null) {
      _firstNameController.text = customer.firstName;
      _lastNameController.text = customer.lastName ?? '';
      _emailController.text = customer.email ?? '';
      _phoneController.text = customer.phone ?? '';
    }

    try {
      final address = await accountRepo.address();
      if (!mounted) return;

      setState(() {
        _addressController.text = address.address ?? '';
        _stateController.text = address.state ?? '';
        _postcodeController.text = address.postcode ?? '';

        final stored = address.city?.trim();
        _city = (stored != null && turkishCities.contains(stored))
            ? stored
            : null;
      });
    } catch (_) {
      // No saved address is normal — leave the fields empty.
    }
  }

  /// KDV and shipping duplicated from OrderController: 20%, free over 5000,
  /// otherwise a flat 150.
  ///
  /// This is a preview. The server recomputes everything from current prices
  /// and ignores whatever the client thinks. If either constant changes on the
  /// backend, this drifts silently — a GET /checkout/quote endpoint would
  /// remove the duplication.
  ({double subtotal, double tax, double shipping, double total}) _totals() {
    const taxRate = 0.20;
    const freeShippingFrom = 5000.0;
    const shippingFlat = 0.00;

    final subtotal = widget.cart.subtotal ?? 0;
    final tax = subtotal * taxRate;
    final shipping = subtotal >= freeShippingFrom ? 0.0 : shippingFlat;

    return (
    subtotal: subtotal,
    tax: tax,
    shipping: shipping,
    total: subtotal + tax + shipping,
    );
  }

  String _money(double value) =>
      '${widget.cart.currencySymbol}${value.toStringAsFixed(2)}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AlertService.showTopAlert(
        context,
        'Lütfen zorunlu alanları doldurun.',
        isError: true,
      );
      return;
    }

    if (_city == null) {
      AlertService.showTopAlert(context, 'Lütfen şehir seçiniz.',
          isError: true);
      return;
    }

    if (!_terms) {
      AlertService.showTopAlert(
        context,
        'Devam etmek için sözleşmeyi onaylayın.',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final body = await apiV2.post('/orders', {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _city,
        'state': _stateController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'payment_method': _method == PaymentMethod.havale ? 'havale' : 'card',
        'notes': _notesController.text.trim(),
        // Laravel's `accepted` rule wants a truthy value.
        'terms': true,
      });

      final response = body as Map<String, dynamic>;
      final orderNumber = response['order_number']?.toString() ?? '';
      final redirectUrl = response['redirect_url']?.toString();

      if (!mounted) return;

      // Havale returns no redirect_url — the order is placed and settled by
      // hand, so it's done here.
      if (redirectUrl == null || redirectUrl.isEmpty) {
        _showSuccess(orderNumber);
        return;
      }

      await PaymentWebViewScreen.open(
        context,
        url: redirectUrl,
        orderNumber: orderNumber,
      );

      if (!mounted) return;
      await _confirmPayment(orderNumber);
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Asks the server what actually happened.
  ///
  /// The callback is server-to-server and may land a moment after the WebView
  /// closes, so this retries briefly before giving up rather than declaring
  /// failure on the first look.
  Future<void> _confirmPayment(String orderNumber) async {
    setState(() => _submitting = true);

    String status = 'pending';

    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        status = await accountRepo.paymentStatus(orderNumber);
        if (status == 'paid' || status == 'failed') break;
      } catch (_) {
        // Keep trying — a transient failure here shouldn't look like a
        // declined card.
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (status == 'paid') {
      _showSuccess(orderNumber, paid: true);
    } else {
      _showPaymentPending(orderNumber, failed: status == 'failed');
    }
  }

  /// Payment didn't complete. The order still exists and the cart still has
  /// the items, so the customer can retry — which is why this isn't phrased
  /// as an error.
  void _showPaymentPending(String orderNumber, {required bool failed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          failed ? Icons.error_outline : Icons.hourglass_top,
          size: 44,
          color: failed ? Colors.red : Colors.orange,
        ),
        title: Text(failed ? 'Ödeme Tamamlanamadı' : 'Ödeme Bekleniyor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (orderNumber.isNotEmpty)
              Text(
                'Sipariş No: $orderNumber',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 8),
            Text(
              failed
                  ? 'Ödemeniz alınamadı. Siparişiniz duruyor, '
                  'tekrar deneyebilir veya havale ile ödeyebilirsiniz.'
                  : 'Ödemeniz kontrol ediliyor. Siparişlerim ekranından '
                  'durumu takip edebilirsiniz.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreenV2()),
              );
            },
            child: const Text('Siparişlerim'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String orderNumber, {bool paid = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline,
            size: 44, color: Colors.green),
        title: const Text('Siparişiniz Alındı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              orderNumber.isEmpty ? '' : 'Sipariş No: $orderNumber',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              paid
                  ? 'Ödemeniz alındı. Siparişiniz hazırlanıyor.'
                  : 'Havale bilgileri için sizinle iletişime geçeceğiz.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreenV2()),
              );
            },
            child: const Text('Siparişlerim'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCity() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CityPickerSheet(selected: _city),
    );

    if (selected != null) setState(() => _city = selected);
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Theme.of(context).cardColor,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder:
    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: blueColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  Widget _card({required Widget child}) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Card(
      elevation: 0,
      color: isLight ? Colors.white : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = _totals();

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
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _submitting ? null : _submit,
            child: Text(
              _submitting ? 'İşleniyor...' : 'Siparişi Onayla',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _card(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _decoration('Ad *'),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Zorunlu'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: _decoration('Soyad'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    decoration: _decoration('E-posta *'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Zorunlu';
                      if (!t.contains('@')) return 'Geçersiz e-posta';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _decoration('Telefon *'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    decoration: _decoration('Adres *'),
                    maxLines: 3,
                    validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickCity,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: _decoration('Şehir *').copyWith(
                              suffixIcon: const Icon(Icons.keyboard_arrow_down),
                            ),
                            isEmpty: _city == null,
                            child: Text(
                              _city ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _postcodeController,
                          decoration: _decoration('Posta Kodu'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _stateController,
                    decoration: _decoration('İlçe / Semt'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ödeme Yöntemi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  RadioListTile<PaymentMethod>(
                    value: PaymentMethod.havale,
                    groupValue: _method,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _method = v!),
                    title: const Text('Havale / EFT (Banka Transferi)'),
                  ),
                  RadioListTile<PaymentMethod>(
                    value: PaymentMethod.card,
                    groupValue: _method,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _method = v!),
                    title: const Text('Kredi / Banka Kartı'),
                    subtitle: const Text(
                      'Sipariş oluşturulur, ödeme onayı sonrası hazırlanır.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),

                  // No card fields here on purpose: entering a card number in
                  // the app makes it PCI-relevant. Once iyzico is wired up the
                  // API returns a redirect_url and the gateway collects the
                  // card on its own hosted page.
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sipariş Özeti',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...widget.cart.items.map(
                        (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: item.image == null
                                ? const Icon(Icons.image_not_supported,
                                size: 40)
                                : Image.network(
                              item.image!,
                              width: 46,
                              height: 46,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported,
                                  size: 40),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.name} x${item.quantity}',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.lineTotal != null)
                            Text(
                              _money(item.lineTotal!),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  _summaryRow('Ara Toplam', _money(totals.subtotal)),
                  _summaryRow('KDV (%20)', _money(totals.tax)),
                  const Divider(),
                  _summaryRow('Toplam', _money(totals.total), isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              child: TextFormField(
                controller: _notesController,
                decoration: _decoration('Sipariş Notu (opsiyonel)'),
                maxLines: 3,
              ),
            ),

            const SizedBox(height: 8),

            CheckboxListTile(
              value: _terms,
              onChanged: (v) => setState(() => _terms = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Ön bilgilendirme koşullarını ve mesafeli satış '
                    'sözleşmesini okudum, onaylıyorum.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? blueColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Half-height searchable province picker, same as the address screen.
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

  /// Turkish needs its own folding — the ASCII toLowerCase leaves İ and I
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
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    title: Text(city, style: const TextStyle(fontSize: 14)),
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