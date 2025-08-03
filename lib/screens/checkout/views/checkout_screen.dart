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
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String selectedCity = "";

  double subtotal = 0.0;
  double kdv = 0.0;
  double total = 0.0;

  late final List<String> turkishCities =
  trStateMap.values.toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    loadUserData();
    calculateTotals();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String billingState = prefs.getString("billing_state") ?? "";
    String billingCity = prefs.getString("billing_city") ?? "";

    setState(() {
      firstNameController.text =
          prefs.getString("billing_first_name") ?? "";
      lastNameController.text =
          prefs.getString("billing_last_name") ?? "";
      addressController.text =
          prefs.getString("billing_address_1") ?? "";
      postcodeController.text =
          prefs.getString("billing_postcode") ?? "";
      phoneController.text = prefs.getString("billing_phone") ?? "";
      emailController.text = prefs.getString("billing_email") ?? "";
      districtController.text = billingCity;

      if (billingState.isNotEmpty &&
          trStateMap.containsKey(billingState)) {
        selectedCity = trStateMap[billingState]!;
      }
    });
  }

  void calculateTotals() {
    double sub = 0.0;
    for (var item in widget.cartItems) {
      double price = 0.0;
      if (item['price'] is num) {
        price = item['price'].toDouble();
      } else if (item['price'] is String) {
        price = double.tryParse(item['price']) ?? 0.0;
      }
      int qty = int.tryParse(item['quantity'].toString()) ?? 1;
      sub += price * qty;
    }

    setState(() {
      subtotal = sub;
      kdv = subtotal * 0.20;
      total = subtotal + kdv;
    });
  }

  InputDecoration _inputDecoration(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.cardColor,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.white54
                : Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.white54
                : Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: blueColor, width: 1.5),
      ),
    );
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final billing = {
                  "first_name": firstNameController.text,
                  "last_name": lastNameController.text,
                  "address_1": addressController.text,
                  "city": districtController.text,
                  "state": trStateMap.entries
                      .firstWhere((e) => e.value == selectedCity)
                      .key,
                  "postcode": postcodeController.text,
                  "country": "TR",
                  "email": emailController.text,
                  "phone": phoneController.text
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

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderSuccessScreen(orderId: order['id']),
                  ),
                );
              } catch (e) {
                AlertService.showTopAlert(context, e.toString(),
                    isError: true);
              }
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
              // BILLING FORM
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                              controller: firstNameController,
                              decoration: _inputDecoration("Ad", theme),
                            )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: TextFormField(
                              controller: lastNameController,
                              decoration: _inputDecoration("Soyad", theme),
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: _inputDecoration("Sokak Adresi", theme),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: postcodeController,
                      decoration: _inputDecoration("Posta Kodu", theme),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: districtController,
                      decoration: _inputDecoration("İlçe / Semt", theme),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCity.isNotEmpty ? selectedCity : null,
                      hint: const Text("Bir şehir seçin"),
                      items: turkishCities
                          .map((city) => DropdownMenuItem(
                          value: city, child: Text(city)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value ?? "";
                        });
                      },
                      decoration: _inputDecoration("Şehir", theme),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: _inputDecoration("Telefon", theme),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: _inputDecoration("E-posta", theme),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CART TABLE
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Sepet Özeti",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ...widget.cartItems.map((item) => Padding(
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
                                const Icon(Icons.image_not_supported,
                                    size: 40),
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
                              "₺${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
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
          Text(label,
              style: TextStyle(
                  fontWeight:
                  isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            "₺${value.toStringAsFixed(2)}",
            style: TextStyle(
                fontWeight:
                isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? blueColor : null),
          ),
        ],
      ),
    );
  }
}