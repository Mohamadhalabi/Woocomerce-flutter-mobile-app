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

  static Future<void> clearWooCart(String token) async {
    const baseUrl = "https://www.aanahtar.com.tr";

    // Step 1: Fetch the cart
    final fetchRes = await http.get(
      Uri.parse('$baseUrl/wp-json/wc/store/cart'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (fetchRes.statusCode != 200) {
      throw Exception('Failed to fetch cart before clearing');
    }

    final cartData = jsonDecode(fetchRes.body);
    final items = cartData['items'] as List;

    // Step 2: Loop through and delete each item
    for (final item in items) {
      final key = item['key'];
      final deleteRes = await http.delete(
        Uri.parse('$baseUrl/wp-json/wc/store/cart/items/$key'), // ✅ correct path
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (deleteRes.statusCode != 200 && deleteRes.statusCode != 204) {
        debugPrint('❌ Failed to remove item $key. Status: ${deleteRes.statusCode}. Body: ${deleteRes.body}');
        throw Exception('Failed to remove item: $key');
      } else {
        debugPrint('✅ Removed item $key');
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
        'productId': productId,
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
    await prefs.remove('guest_cart');
  }

  static Future<void> clearGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static Future<void> saveGuestCartList(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart));
  }

}