// lib/repositories/auth_repository.dart
//
// Replaces the JWT + custom-auth WordPress calls in the old ApiService.
//
// Owns the bearer token: nothing else should read or write it. Call
// restoreSession() once at startup, then login/verifyPhoneCode to sign in and
// logout to sign out.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer_model.dart';
import '../services/api_client.dart';

class AuthRepository {
  /// Kept as 'auth_token' — the key the current app already uses, so existing
  /// installs stay signed in through the update.
  static const _tokenKey = 'auth_token';

  /// Last known customer, cached as JSON. Lets the app render the signed-in
  /// state on the first frame instead of waiting ~450ms for /auth/me.
  static const _customerKey = 'auth_customer';

  final ApiClient _client;

  /// Fired after sign-in and sign-out. Wire this to your cart and home
  /// providers: prices and home sections are cached per audience (guest vs
  /// signed-in), so both must refetch when this changes.
  final void Function(bool signedIn)? onAuthChanged;

  CustomerModel? _customer;

  AuthRepository(this._client, {this.onAuthChanged});

  CustomerModel? get customer => _customer;
  bool get isSignedIn => _customer != null;

  // ── Session ─────────────────────────────────────────────────────────────

  /// Restores a stored token and verifies it against the server.
  ///
  /// Returns null when there is no token, or when the stored one has been
  /// revoked — an admin un-approving an account or a logout on another device
  /// both invalidate it, so a token on disk is not proof of a session.
  /// Reads the token and the cached customer from disk. No network.
  ///
  /// Called at startup so the first frame already knows whether someone is
  /// signed in. Verifying against the server costs a round trip — ~450ms on
  /// mobile — and blocking the splash screen on it made every cold start feel
  /// slow for no benefit: the cached answer is right almost every time.
  Future<CustomerModel?> loadCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) return null;

    _client.setBearerToken(token);

    final raw = prefs.getString(_customerKey);
    if (raw == null) return null;

    try {
      _customer = CustomerModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      onAuthChanged?.call(true);
      return _customer;
    } catch (_) {
      // Shape changed between releases — treat as no cache and let the
      // background verify repopulate it.
      return null;
    }
  }

  /// Verifies the stored token against the server and refreshes the cache.
  ///
  /// Safe to run in the background after [loadCachedSession]: it only ever
  /// corrects the state. A revoked token — an admin un-approving an account,
  /// or a logout on another device — signs the customer out at this point
  /// rather than at launch.
  Future<CustomerModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) return null;

    _client.setBearerToken(token);

    try {
      final body = await _client.get('/auth/me');
      final json = (body as Map<String, dynamic>)['customer']
      as Map<String, dynamic>;

      _customer = CustomerModel.fromJson(json);
      await prefs.setString(_customerKey, jsonEncode(json));

      onAuthChanged?.call(true);
      return _customer;
    } on ApiException catch (e) {
      // A network blip shouldn't sign anyone out — keep the token and let the
      // app retry. Only a rejected token gets cleared.
      if (e.isNetwork) rethrow;
      await _clearSession();
      return null;
    }
  }

  Future<void> _persist(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_customerKey, jsonEncode(session.customer.toJson()));
    _client.setBearerToken(session.token);
    _customer = session.customer;
    onAuthChanged?.call(true);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_customerKey);
    _client.setBearerToken(null);
    _customer = null;
    onAuthChanged?.call(false);
  }

  // ── Email sign-in ───────────────────────────────────────────────────────

  /// Throws [PendingApprovalException] when the account exists but hasn't been
  /// approved, and [ApiException] (422) for wrong credentials.
  ///
  /// The guest cart is merged automatically: ApiClient sends X-Cart-Token on
  /// this request, and the server folds that basket into the customer's.
  Future<CustomerModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = await _client.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      final session = AuthSession.fromJson(body as Map<String, dynamic>);
      await _persist(session);
      return session.customer;
    } on ApiException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // ── Phone sign-in ───────────────────────────────────────────────────────
  //
  // Endpoints per backend-requirements.md §1. Not live yet — these will throw
  // 404 until the backend ships them.

  /// Sends an SMS code. Responds the same way whether or not the number is
  /// registered, so a failure here doesn't mean the number is unknown.
  Future<String> requestPhoneCode(String phone) async {
    final body = await _client.post('/auth/phone/request-code', {
      'phone': phone.trim(),
    });

    return (body as Map<String, dynamic>?)?['message']?.toString() ??
        'Doğrulama kodu gönderildi.';
  }

  /// Exchanges the SMS code for a session. Same result as [login].
  Future<CustomerModel> verifyPhoneCode({
    required String phone,
    required String code,
  }) async {
    try {
      final body = await _client.post('/auth/phone/verify-code', {
        'phone': phone.trim(),
        'code': code.trim(),
      });

      final session = AuthSession.fromJson(body as Map<String, dynamic>);
      await _persist(session);
      return session.customer;
    } on ApiException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // ── Registration ────────────────────────────────────────────────────────

  /// Creates an account. Returns the server's message.
  ///
  /// No session is created: accounts are unusable until an admin approves
  /// them, so send the customer to a "pending approval" screen rather than
  /// into the app.
  ///
  /// Note the field names — the old app sent a single `name`, which the API
  /// rejects with a 422. Split it before calling.
  Future<String> register({
    required String firstName,
    String? lastName,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
    String? companyName,
  }) async {
    final body = await _client.post('/auth/register', {
      'first_name': firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty)
        'last_name': lastName.trim(),
      'email': email.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'password': password,
      // Laravel's `confirmed` rule requires exactly this key.
      'password_confirmation': passwordConfirmation,
      if (companyName != null && companyName.trim().isNotEmpty)
        'company_name': companyName.trim(),
    });

    return (body as Map<String, dynamic>?)?['message']?.toString() ??
        'Kaydınız alındı.';
  }

  /// Phone-first registration, for customers without an email address.
  /// Backend endpoint per backend-requirements.md §1.
  Future<String> registerWithPhone({
    required String phone,
    required String firstName,
    String? lastName,
    String? email,
    required String password,
    required String passwordConfirmation,
    String? companyName,
  }) async {
    final body = await _client.post('/auth/phone/register', {
      'phone': phone.trim(),
      'first_name': firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty)
        'last_name': lastName.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (companyName != null && companyName.trim().isNotEmpty)
        'company_name': companyName.trim(),
    });

    return (body as Map<String, dynamic>?)?['message']?.toString() ??
        'Kaydınız alındı.';
  }

  Future<String> forgotPassword(String email) async {
    final body = await _client.post('/auth/forgot-password', {
      'email': email.trim(),
    });

    return (body as Map<String, dynamic>?)?['message']?.toString() ??
        'Şifre sıfırlama bağlantısı gönderildi.';
  }

  // ── Profile ─────────────────────────────────────────────────────────────

  Future<CustomerModel> fetchProfile() async {
    final body = await _client.get('/auth/me');
    _customer = CustomerModel.fromJson(
      (body as Map<String, dynamic>)['customer'] as Map<String, dynamic>,
    );
    return _customer!;
  }

  /// Updates the profile, and optionally the password in the same call —
  /// PATCH /auth/me handles both. Supplying [newPassword] requires
  /// [currentPassword]; the server rejects the change otherwise.
  ///
  /// All profile fields are sent every time. The controller validates
  /// first_name and email as required, so a partial payload fails.
  Future<CustomerModel> updateProfile({
    required String firstName,
    String? lastName,
    required String email,
    String? phone,
    String? companyName,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) async {
    final payload = <String, dynamic>{
      'first_name': firstName.trim(),
      'last_name': lastName?.trim(),
      'email': email.trim(),
      'phone': phone?.trim(),
      'company_name': companyName?.trim(),
    };

    if (newPassword != null && newPassword.isNotEmpty) {
      payload['current_password'] = currentPassword;
      payload['password'] = newPassword;
      payload['password_confirmation'] = newPasswordConfirmation ?? newPassword;
    }

    final body = await _client.patch('/auth/me', payload);

    _customer = CustomerModel.fromJson(
      (body as Map<String, dynamic>)['customer'] as Map<String, dynamic>,
    );
    return _customer!;
  }

  // ── Sign out and deletion ───────────────────────────────────────────────

  /// Clears the local session whatever the server says — a failed request
  /// should never leave someone stuck signed in.
  ///
  /// The cart token is cleared too: the server-side cart now belongs to the
  /// customer, and its old guest token no longer resolves to it.
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } on ApiException {
      // Ignored on purpose.
    } finally {
      await _clearSession();
      await _client.clearCartToken();
    }
  }

  /// Permanent account deletion. Required by the App Store and Play Store.
  /// Backend endpoint per backend-requirements.md §2.
  Future<void> deleteAccount() async {
    await _client.delete('/auth/me');
    await _clearSession();
    await _client.clearCartToken();
  }

  // ── Errors ──────────────────────────────────────────────────────────────

  Exception _mapAuthError(ApiException e) {
    if (e.isValidation && _looksPendingApproval(e)) {
      return PendingApprovalException(e.message);
    }
    return e;
  }

  /// Both wrong credentials and an unapproved account come back as a 422 with
  /// the message under `errors.email`, so the two are only distinguishable by
  /// the text.
  ///
  /// Fragile by nature — ask the backend to return a stable code
  /// (e.g. `"code": "pending_approval"`) and match on that instead.
  bool _looksPendingApproval(ApiException e) {
    final message = (e.firstError('email') ?? e.message).toLowerCase();
    return message.contains('onayla');
  }
}

/// The account exists and the credentials were right, but an admin hasn't
/// approved it yet. Show the message and a support contact — not a retry.
class PendingApprovalException implements Exception {
  final String message;
  const PendingApprovalException(this.message);

  @override
  String toString() => message;
}