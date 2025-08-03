import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants.dart'; // for blueColor + trStateMap

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

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

  // Get list of cities from trStateMap values
  late final List<String> turkishCities =
  trStateMap.values.toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    loadUserData();
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

      // İlçe / Semt → use WooCommerce city directly
      districtController.text = billingCity;

      // Auto-select dropdown from state code
      if (billingState.isNotEmpty && trStateMap.containsKey(billingState)) {
        selectedCity = trStateMap[billingState]!;
      } else {
        selectedCity = "";
      }
    });
  }

  Widget _inputField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blueColor, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ödeme', style: TextStyle(color: Colors.white)),
        backgroundColor: blueColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: blueColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Send checkout request
            }
          },
          child: const Text("Siparişi Onayla",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Fatura Detayları",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20),

                // Name fields
                Row(
                  children: [
                    Expanded(child: _inputField("Ad", firstNameController)),
                    const SizedBox(width: 10),
                    Expanded(child: _inputField("Soyad", lastNameController)),
                  ],
                ),
                const SizedBox(height: 16),

                // Country (read-only)
                _inputField("Ülke", TextEditingController(text: "Türkiye"),
                    readOnly: true),
                const SizedBox(height: 16),

                _inputField("Sokak Adresi", addressController),
                const SizedBox(height: 16),

                _inputField("Posta Kodu", postcodeController),
                const SizedBox(height: 16),

                _inputField("İlçe / Semt", districtController),
                const SizedBox(height: 16),

                // State → City dropdown
                DropdownButtonFormField<String>(
                  value: selectedCity.isNotEmpty ? selectedCity : null,
                  hint: const Text("Bir şehir seçin"),
                  items: turkishCities
                      .map((city) =>
                      DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value ?? "";
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Şehir",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: blueColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _inputField("Telefon", phoneController),
                const SizedBox(height: 16),

                _inputField("E-posta", emailController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}