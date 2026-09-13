// lib/services/recently_viewed_service.dart
//
// Products the customer has opened, most recent first.
//
// Stores the full product card so the list can show real cards with add-to-cart
// — but records the audience and currency each entry was captured under. Prices
// differ between guests and signed-in customers and between currencies, so on
// read anything captured under different conditions has its price stripped
// rather than shown. A stale price next to a live one is worse than none.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog_product.dart';
import 'app_api.dart';
import 'currency_service.dart';

class RecentlyViewedService {
  // A new key: the old 'recently_viewed' holds the WooCommerce shape with
  // integer ids, which can't be read back.
  static const _key = 'recently_viewed_v2';
  static const _limit = 15;

  static String get _context =>
      '${authRepo.isSignedIn ? 'auth' : 'guest'}:${CurrencyService.current}';

  static Future<List<ProductModel>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final context = _context;

    return raw
        .map((entry) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        final card = Map<String, dynamic>.from(
          map['card'] as Map<String, dynamic>,
        );

        // Captured as a guest, or in another currency: keep the product,
        // drop the figure.
        if (map['ctx'] != context) {
          card['price'] = null;
          card['old_price'] = null;
          card['discount'] = null;
          card['price_visible'] = false;
        }

        return ProductModel.fromJson(card);
      } catch (_) {
        return null;
      }
    })
        .whereType<ProductModel>()
        .where((p) => p.slug.isNotEmpty)
        .toList();
  }

  /// Adds to the front. Re-viewing moves it up rather than duplicating.
  static Future<void> add(Map<String, dynamic> card) async {
    final slug = card['slug']?.toString();
    if (slug == null || slug.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    raw.removeWhere((entry) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        return (map['card'] as Map)['slug'] == slug;
      } catch (_) {
        return true; // drop unreadable entries while we're here
      }
    });

    raw.insert(0, jsonEncode({'ctx': _context, 'card': card}));

    await prefs.setStringList(
      _key,
      raw.length > _limit ? raw.sublist(0, _limit) : raw,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}