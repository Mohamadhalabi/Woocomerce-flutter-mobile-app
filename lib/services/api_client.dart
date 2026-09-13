// lib/services/api_client.dart
//
// Replaces the per-method dotenv.load() + _buildHeaders() pattern in the old
// ApiService. One instance, created once in main(), shared by all repositories.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A failed request. [errors] holds Laravel's 422 validation bag, keyed by
/// field name, so forms can show messages against the right input.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.statusCode, this.message, {this.errors});

  bool get isNetwork => statusCode == 0;
  bool get isUnauthenticated => statusCode == 401;
  bool get isValidation => statusCode == 422;

  /// First message for a field, e.g. firstError('email').
  String? firstError(String field) {
    final list = errors?[field];
    if (list is List && list.isNotEmpty) return list.first.toString();
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const _cartTokenKey = 'cart_token';

  final String baseUrl;
  final String apiKey;
  final String secretKey;

  /// Required by EnsureApiClient middleware on every /api route. Without it
  /// the API answers {"message":"Client key required."} with a 401.
  final String clientKey;

  String _language = 'tr';
  String _currency = 'TRY';

  String? _bearerToken;
  String? _cartToken;

  /// ONE client for the app's lifetime.
  ///
  /// The top-level http.get()/post() helpers open a new connection per call —
  /// a full TCP handshake plus TLS negotiation every time, which on mobile is
  /// most of the latency of a small request. A persistent client keeps the
  /// connection alive and reuses it, so only the first request pays that cost.
  final http.Client _http = http.Client();

  ApiClient({
    required this.baseUrl,
    required this.apiKey,
    required this.secretKey,
    this.clientKey = '',
  });

  /// Only on app shutdown — closing it mid-session forces a new handshake on
  /// the next request.
  void dispose() => _http.close();

  static Future<ApiClient> fromEnv() async {
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL missing from .env');
    }

    final client = ApiClient(
      baseUrl: baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      apiKey: dotenv.env['API_KEY'] ?? '',
      secretKey: dotenv.env['SECRET_KEY'] ?? '',
      clientKey: dotenv.env['CLIENT_KEY_APP'] ?? '',
    );

    await client.loadCartToken();
    return client;
  }

  // ── Locale ──────────────────────────────────────────────────────────────

  void setLocale({String? language, String? currency}) {
    if (language != null) _language = language;
    if (currency != null) _currency = currency;
  }

  String get currency => _currency;

  // ── Auth token ──────────────────────────────────────────────────────────

  bool get isAuthenticated => _bearerToken != null;

  void setBearerToken(String? token) => _bearerToken = token;

  // ── Cart token ──────────────────────────────────────────────────────────
  //
  // CartService::resolve() reads the X-Cart-Token header. With no token it
  // CREATES a new cart row, so never call /cart just to see if one exists —
  // check hasCartToken first and render an empty cart locally.

  bool get hasCartToken => _cartToken != null;

  Future<void> loadCartToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cartToken = prefs.getString(_cartTokenKey);
  }

  Future<void> _captureCartToken(String value) async {
    if (value == _cartToken) return;
    _cartToken = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartTokenKey, value);
  }

  Future<void> clearCartToken() async {
    _cartToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartTokenKey);
  }

  // ── Requests ────────────────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send(() => _http.post(_uri(path), headers: _headers(), body: _encode(body)));

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send(() => _http.patch(_uri(path), headers: _headers(), body: _encode(body)));

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _send(() => _http.put(_uri(path), headers: _headers(), body: _encode(body)));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.delete(_uri(path, query), headers: _headers()));

  // ── Internals ───────────────────────────────────────────────────────────

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Language': _language,
      // Renamed: the old app sent 'currency', the API reads X-Currency.
      'X-Currency': _currency,
    };

    if (clientKey.isNotEmpty) headers['X-Client-Key'] = clientKey;
    if (apiKey.isNotEmpty) headers['api-key'] = apiKey;
    if (secretKey.isNotEmpty) headers['secret-key'] = secretKey;
    if (_bearerToken != null) headers['Authorization'] = 'Bearer $_bearerToken';
    if (_cartToken != null) headers['X-Cart-Token'] = _cartToken!;

    return headers;
  }

  String? _encode(Map<String, dynamic>? body) =>
      body == null ? null : jsonEncode(body);

  /// Builds the query string. Lists become repeated `key[]=` params, which is
  /// what the `array` validation rules on /products and /filters require —
  /// a comma-joined string is rejected with a 422.
  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');

    if (query == null || query.isEmpty) return uri;

    final params = <String, dynamic>{};

    query.forEach((key, value) {
      if (value == null) return;

      if (value is List) {
        final items = value.map((v) => v.toString()).where((v) => v.isNotEmpty).toList();
        if (items.isNotEmpty) params['$key[]'] = items;
      } else if (value is bool) {
        // Laravel's `boolean` rule accepts "1"/"0".
        if (value) params[key] = '1';
      } else {
        final str = value.toString();
        if (str.isNotEmpty) params[key] = str;
      }
    });

    return uri.replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late http.Response response;

    try {
      response = await request().timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException(0, 'Bağlantı hatası. Lütfen tekrar deneyin.');
    }

    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Every cart and order response carries the cart token; grabbing it here
      // means no caller has to remember to.
      if (body is Map && body['token'] is String) {
        await _captureCartToken(body['token'] as String);
      }
      return body;
    }

    throw ApiException(
      response.statusCode,
      _messageFrom(body, response.statusCode),
      errors: body is Map ? body['errors'] as Map<String, dynamic>? : null,
    );
  }

  String _messageFrom(dynamic body, int status) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }

    // Validation errors sometimes carry the useful text only in the bag —
    // login failures arrive this way (ValidationException::withMessages).
    if (body is Map && body['errors'] is Map) {
      final first = (body['errors'] as Map).values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }

    switch (status) {
      case 401:
        return 'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.';
      case 404:
        return 'Kayıt bulunamadı.';
      default:
        return 'Bir hata oluştu ($status).';
    }
  }
}