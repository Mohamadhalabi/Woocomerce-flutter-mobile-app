// lib/services/currency_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/account_repository.dart';
import 'app_api.dart';
import 'taxonomy_service.dart';

class CurrencyService {
  static const _key = 'selected_currency';
  static const fallback = 'TRY';

  static String _current = fallback;
  static List<Currency>? _available;

  /// Bumped on every switch. Screens that keep their state alive — the home
  /// tab lives in an IndexedStack and never rebuilds on its own — listen to
  /// this and refetch, otherwise they keep showing the old currency until the
  /// customer pulls to refresh.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static String get current => _current;

  /// Reads the stored choice and applies it to ApiClient. Call from
  /// initAppApi() BEFORE the first request, or the first screen loads in the
  /// wrong currency.
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _current = prefs.getString(_key) ?? fallback;
    apiV2.setLocale(currency: _current);
  }

  /// The options for the picker. Falls back to a sensible list when the
  /// endpoint fails — a broken switcher is worse than a static one.
  static Future<List<Currency>> available() async {
    final cached = _available;
    if (cached != null) return cached;

    try {
      final list = await accountRepo.currencies();
      if (list.isNotEmpty) {
        _available = list;
        return list;
      }
    } catch (_) {
      // Fall through.
    }

    return const [
      Currency(code: 'TRY', symbol: '₺'),
      Currency(code: 'USD', symbol: '\$'),
      Currency(code: 'EUR', symbol: '€'),
    ];
  }

  /// Switches currency. Returns false when it's already selected.
  static Future<bool> set(String code) async {
    if (code == _current) return false;

    _current = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);

    // The header every priced endpoint reads.
    apiV2.setLocale(currency: code);

    // Every cached figure is in the old currency now.
    TaxonomyService.clearAll();

    // Tells live screens to refetch.
    revision.value++;

    return true;
  }

  static String symbolFor(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'TRY':
        return '₺';
      default:
        return code;
    }
  }
}