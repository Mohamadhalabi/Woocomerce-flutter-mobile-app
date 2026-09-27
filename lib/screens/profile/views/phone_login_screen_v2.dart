// lib/screens/profile/views/phone_login_screen_v2.dart
//
// Sign-in with an SMS code (Twilio Verify on the server):
//   1. the customer enters their mobile number -> POST /auth/phone/request-code
//   2. types the 6-digit code from the SMS     -> POST /auth/phone/verify-code
//
// The number must already be on a customer account; the server says so if not,
// and sends no SMS in that case.
//
// After sign-in this does exactly what LoginScreenV2 does: clears the
// per-audience caches and claims the guest cart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../entry_point.dart';
import '../../../repositories/auth_repository.dart';
import '../../../services/alert_service.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../../services/taxonomy_service.dart';

class PhoneLoginScreenV2 extends StatefulWidget {
  const PhoneLoginScreenV2({super.key});

  @override
  State<PhoneLoginScreenV2> createState() => _PhoneLoginScreenV2State();
}

class _PhoneLoginScreenV2State extends State<PhoneLoginScreenV2> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();

  /// Twilio Verify sends 6 digits by default.
  static const _codeLength = 6;

  /// Twilio allows 5 sends per number per 10 minutes, so the resend button
  /// waits a minute between attempts.
  static const _resendSeconds = 60;

  bool _codeSent = false;
  bool _isLoading = false;
  int _resendIn = 0;
  Timer? _timer;

  final Color primaryColor = const Color(0xFF2D83B0);

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────

  /// Accepts 05XXXXXXXXX or 5XXXXXXXXX. The server normalises again, so this
  /// only catches obvious typos before spending an SMS.
  String? _validatePhone(String? value) {
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);

    if (digits.length != 10 || !digits.startsWith('5')) {
      return 'Geçerli bir cep telefonu girin (05XX XXX XX XX)';
    }
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final message = await authRepo.requestPhoneCode(_phoneController.text);
      if (!mounted) return;

      _codeController.clear();
      setState(() => _codeSent = true);
      _startCountdown();

      AlertService.showTopAlert(context, message, isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(
        context,
        e.firstError('phone') ?? e.message,
        isError: true,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.length != _codeLength) {
      AlertService.showTopAlert(
        context,
        'Lütfen $_codeLength haneli kodu girin',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customer = await authRepo.verifyPhoneCode(
        phone: _phoneController.text,
        code: code,
      );

      // Prices and home sections are cached per audience — without this the
      // customer signs in and still sees the guest version.
      await TaxonomyService.onAuthChanged();

      // Claims the guest cart (the server merges it using X-Cart-Token).
      try {
        await cartRepo.fetchOrCreate();
      } catch (_) {
        // A failed merge shouldn't block the sign-in.
      }

      if (!mounted) return;

      AlertService.showTopAlert(
        context,
        'Hoş geldiniz, ${customer.firstName}',
        isError: false,
      );

      // Clears both login screens off the stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => EntryPoint(onLocaleChange: (_) {})),
        (_) => false,
      );
    } on PendingApprovalException catch (e) {
      if (!mounted) return;
      _showPendingApproval(e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      _codeController.clear();
      AlertService.showTopAlert(
        context,
        e.firstError('code') ?? e.firstError('phone') ?? e.message,
        isError: true,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeNumber() {
    _timer?.cancel();
    _codeController.clear();
    setState(() {
      _codeSent = false;
      _resendIn = 0;
    });
  }

  /// Same dialog as email login: the code was right, the account just isn't
  /// approved yet.
  void _showPendingApproval(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabınız Onay Bekliyor'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Telefon ile Giriş',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 10),
          Center(
            child: Image.asset('assets/logo/aanahtar-logo.webp', height: 70),
          ),
          const SizedBox(height: 30),
          if (!_codeSent) ..._phoneStep() else ..._codeStep(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _phoneStep() => [
        const Text(
          'Kayıtlı cep telefonu numaranızı girin. Size SMS ile bir '
          'doğrulama kodu göndereceğiz.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        Form(
          key: _phoneFormKey,
          child: TextFormField(
            controller: _phoneController,
            decoration: _inputDecoration(
              'Cep Telefonu',
              hint: '05XX XXX XX XX',
              prefix: const Icon(Icons.phone_android),
            ),
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: _validatePhone,
            onFieldSubmitted: (_) => _sendCode(),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton('Kod gönder', _sendCode),
      ];

  List<Widget> _codeStep() => [
        Text(
          '${_phoneController.text} numarasına gönderilen '
          '$_codeLength haneli kodu girin.',
          style: const TextStyle(fontSize: 14),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _isLoading ? null : _changeNumber,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              'Numarayı değiştir',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: _codeLength,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 10,
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Doğrulama Kodu').copyWith(
            counterText: '',
          ),
          // Submits by itself once all digits are in.
          onChanged: (v) {
            if (v.length == _codeLength && !_isLoading) _verify();
          },
        ),
        const SizedBox(height: 24),
        _primaryButton('Doğrula ve giriş yap', _verify),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: (_resendIn > 0 || _isLoading) ? null : _sendCode,
            child: Text(
              _resendIn > 0
                  ? 'Kodu tekrar gönder (${_resendIn}s)'
                  : 'Kodu tekrar gönder',
              style: TextStyle(
                color: _resendIn > 0 ? Colors.grey : primaryColor,
              ),
            ),
          ),
        ),
      ];
}
