import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/alert_service.dart';
import '../../constants.dart';
import 'iyzico_challenge_webview.dart';

class IyzicoCardFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic> billingTemplate; // first/last/city/state/phone/email...
  final double total;

  const IyzicoCardFormScreen({
    super.key,
    required this.cartItems,
    required this.billingTemplate,
    required this.total,
  });

  @override
  State<IyzicoCardFormScreen> createState() => _IyzicoCardFormScreenState();
}

class _IyzicoCardFormScreenState extends State<IyzicoCardFormScreen> {
  final _form = GlobalKey<FormState>();
  final name  = TextEditingController();
  final number= TextEditingController();
  final month = TextEditingController();
  final year  = TextEditingController();
  final cvc   = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    name.text = "${widget.billingTemplate['first_name'] ?? ''} ${widget.billingTemplate['last_name'] ?? ''}".trim();
  }

  @override
  void dispose() {
    name.dispose(); number.dispose(); month.dispose(); year.dispose(); cvc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);

    try {
      final billing = Map<String, dynamic>.from(widget.billingTemplate);

      final card = {
        'holder'  : name.text.trim(),
        'number'  : number.text.replaceAll(RegExp(r'\D'), ''),
        'expMonth': month.text.trim(),
        'expYear' : year.text.trim(),   // “26” or “2026” are fine (backend normalizes)
        'cvc'     : cvc.text.trim(),
        'registerCard': false,
      };

      final resp = await ApiService.payIyzicoCard(
        billing   : billing,
        cartItems : widget.cartItems,
        total     : widget.total,
        card      : card,
        use3ds    : true,
      );

      final orderId = (resp['orderId'] ?? '').toString();

      // A) Immediate success (no 3DS)
      if (resp['paid'] == true) {
        if (!mounted) return;
        Navigator.pop(context, {'orderId': orderId, 'paid': true});
        return;
      }

      // B) 3DS step required
      final html = (resp['threeDSHtml'] ?? '').toString();
      if (html.isEmpty) {
        throw Exception('3DS başlatılamadı (HTML boş).');
      }

      final bool? ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => IyzicoChallengeWebView(html: html, orderId: orderId),
        ),
      );

      if (!mounted) return;

      if (ok == true) {
        Navigator.pop(context, {'orderId': orderId, 'paid': true});
      } else {
        AlertService.showTopAlert(context, 'Ödeme tamamlanmadı.', isError: true);
      }
    } catch (e) {
      AlertService.showTopAlert(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String l) => InputDecoration(
    labelText: l,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kart Bilgileri')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('₺${widget.total.toStringAsFixed(2)} öde'),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: name,
                decoration: _dec('Kart Üzerindeki İsim'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: number,
                decoration: _dec('Kart Numarası'),
                keyboardType: TextInputType.number,
                validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 12 ? 'Geçersiz' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: month,
                      decoration: _dec('Ay (MM)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v ?? '').length < 2 ? 'MM' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: year,
                      decoration: _dec('Yıl (YY/YYYY)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v ?? '').length < 2 ? 'YY' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: cvc,
                      decoration: _dec('CVC'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v ?? '').length < 3 ? 'CVC' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
