import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const _cartKey = 'guest_cart';
  static const baseUrl = 'https://www.aanahtar.com.tr';
  static VoidCallback? onGuestCartUpdated;

  // ─────────────────────────────────────────────
  // 🛒 Store API: Authenticated WooCommerce Cart
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchWooCart(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wp-json/wc/store/cart'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to fetch cart: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final items = data['items'];

    if (items == null || items is! List) {
      throw Exception("Invalid cart format");
    }

    return items.map<Map<String, dynamic>>((item) {
      final itemMap = Map<String, dynamic>.from(item);
      itemMap['key'] = itemMap['key']; // Keep cart item key
      return itemMap;
    }).toList();
  }

  static Future<void> addToWooCart(String token, int productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wp-json/wc/store/cart/add-item'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': productId,
        'quantity': quantity,
      }),
    );
    if (response.statusCode != 201) {
      debugPrint('❌ Failed to add to cart: ${response.body}');
      throw Exception('Failed to add to cart');
    } else {
      debugPrint('✅ Product added to cart successfully.');
    }
  }

  static Future<void> setWooCartQuantity(
      String token,
      String cartItemKey,
      int quantity, {
        required int productId,
      }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/wp-json/wc/store/cart/items/$cartItemKey'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'quantity': quantity}),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to update quantity: ${response.body}');
    }
  }

  static Future<void> removeWooCartItem(String token, String cartItemKey) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wp-json/wc/store/cart/items/$cartItemKey'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('❌ Failed to remove item: ${response.body}');
    }
  }

// CartService.dart
  static const String _storeBase = 'https://www.aanahtar.com.tr/wp-json/wc/store';

  static Future<void> clearWooCart(String token, {List<String>? knownKeys}) async {
    try {
      final bulk = await http
          .delete(
        Uri.parse('$_storeBase/cart/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 8));

      if (bulk.statusCode == 200 || bulk.statusCode == 204) {
        return; // done
      }
      // If the endpoint isn’t supported or returns 4xx/5xx, fall through to fallback.
      debugPrint('Bulk clear not available or failed (${bulk.statusCode}). Falling back…');
    } catch (e) {
      debugPrint('Bulk clear error: $e — falling back to per-item deletes.');
    }

    // --- Fallback: delete items in PARALLEL using known keys (or fetch if needed) ---
    List<String> keys = knownKeys ?? [];

    if (keys.isEmpty) {
      // As a last resort, fetch cart once to get keys
      final fetchRes = await http.get(
        Uri.parse('$_storeBase/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (fetchRes.statusCode != 200) {
        throw Exception('Failed to fetch cart before clearing');
      }
      final cartData = jsonDecode(fetchRes.body);
      final items = (cartData['items'] as List? ?? []);
      keys = items
          .map((it) => it is Map<String, dynamic> ? it['key']?.toString() : null)
          .where((k) => k != null && k!.isNotEmpty)
          .cast<String>()
          .toList();
    }

    if (keys.isEmpty) return;

    // Delete all items concurrently
    final futures = keys.map((k) {
      return http.delete(
        Uri.parse('$_storeBase/cart/items/$k'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }).toList();

    final results = await Future.wait(futures);

    // Validate results
    for (final r in results) {
      if (r.statusCode != 200 && r.statusCode != 204) {
        debugPrint('❌ Failed to remove item. Status: ${r.statusCode}. Body: ${r.body}');
        throw Exception('Failed to remove one or more items while clearing cart');
      }
    }
  }

  static Future<void> addItemToGuestCart({
    required int productId,
    required String title,
    required String image,
    required int quantity,
    required double price,
    double? salePrice,
    required String sku,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString(_cartKey);
    List<Map<String, dynamic>> cart = [];

    if (cartData != null) {
      cart = List<Map<String, dynamic>>.from(jsonDecode(cartData));
    }

    final existingIndex = cart.indexWhere((item) => item['productId'] == productId);

    if (existingIndex != -1) {
      cart[existingIndex]['quantity'] += quantity;
    } else {
      cart.add({
        'id': productId,           // match logged-in cart format
        'product_id': productId,   // ✅ key that CartScreen is expecting
        'productId': productId,    // keep old key for compatibility
        'title': title,
        'image': image,
        'quantity': quantity,
        'price': price,
        'salePrice': salePrice,
        'sku': sku,
        'category': category,
      });
    }

    await prefs.setString(_cartKey, jsonEncode(cart));

    // 🔔 Notify cart screen to reload
    if (onGuestCartUpdated != null) {
      onGuestCartUpdated!();
    }
  }

  // ─────────────────────────────────────────────
  // 🧰 Guest Cart (Local Storage)
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cartKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> saveGuestCart(List<Map<String, dynamic>> updatedCart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(updatedCart));
    onGuestCartUpdated?.call();
  }

  static Future<void> clearGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static Future<void> saveGuestCartList(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart));
  }

  static Future<void> clearAll({String? token}) async {
    // Try clearing Woo cart if we have a token (logged-in user).
    if (token != null && token.isNotEmpty) {
      try {
        await clearWooCart(token);
      } catch (e) {
        debugPrint('clearWooCart failed: $e'); // do not block local clear
      }
    }

    // Always clear guest/local cart too (covers mixed states / safety).
    try {
      await clearGuestCart();
    } finally {
      onGuestCartUpdated?.call();
    }
  }

}