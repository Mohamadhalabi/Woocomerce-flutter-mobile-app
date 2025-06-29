import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class CartService {
  static Future<void> addItemToGuestCart({
    required int productId,
    required String title,
    required String image,
    required int quantity,
    required double price,
    double? salePrice,
    required String sku,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString(_cartKey);
    List<Map<String, dynamic>> cart = [];

    if (cartData != null) {
      cart = List<Map<String, dynamic>>.from(jsonDecode(cartData));
    }

    // Check if product already exists in cart
    final existingIndex = cart.indexWhere((item) => item['productId'] == productId);

    if (existingIndex != -1) {
      // Update quantity if exists
      cart[existingIndex]['quantity'] += quantity;
    } else {
      // Add new product
      cart.add({
        'productId': productId,
        'title': title,
        'image': image,
        'quantity': quantity,
        'price': price,
        'salePrice': salePrice,
        'sku': sku,
      });
    }

    await prefs.setString(_cartKey, jsonEncode(cart));
  }

  static const _cartKey = 'guest_cart';
  // Guest Cart (local)
  static Future<void> saveGuestCart(List<Map<String, dynamic>> updatedCart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(updatedCart));
  }

  static Future<List<Map<String, dynamic>>> getGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cartKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }
  // clear guest cart
  static Future<void> clearGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
  // save guest cart
  static Future<void> saveGuestCartList(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart));
  }

  // WooCommerce Add to Cart
  static Future<void> addToWooCart(String token, int productId, int quantity) async {
    await dotenv.load();
    const baseUrl = "https://www.aanahtar.com.tr";

    final bodyData = {
      'id': productId.toString(),
      'quantity': quantity.toString(), // ✅ fixed
    };

    print('📦 Sending to WooCommerce: ${jsonEncode(bodyData)}');
    print('➡️ id: ${productId} (${productId.runtimeType}), quantity: ${quantity} (${quantity.runtimeType})');

    final response = await http.post(
      Uri.parse('$baseUrl/wp-json/cocart/v2/cart/add-item'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode != 200) {
      print('❌ WooCommerce Error Response: ${response.body}');
      throw Exception('Add to cart failed: ${response.body}');
    } else {
      print('✅ Item added successfully!');
    }
  }

  // WooCommerce Get Cart
  static Future<List<Map<String, dynamic>>> fetchWooCart(String token) async {
    await dotenv.load();
    const baseUrl = "https://www.aanahtar.com.tr";

    final response = await http.get(
      Uri.parse('$baseUrl/wp-json/cocart/v2/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('🛒 Raw response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Fetch cart failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    print('📥 Decoded cart data: $data');

    final items = data['items'];

    if (items == null || items is! List) {
      print('❌ Unexpected cart format: ${items.runtimeType}');
      throw Exception("Invalid cart format: ${items.runtimeType}");
    }

    // Each item in list should contain 'item_key'
    return items.map<Map<String, dynamic>>((item) {
      final itemMap = Map<String, dynamic>.from(item);
      itemMap['key'] = itemMap['item_key']; // 👈 add the key properly
      return itemMap;
    }).toList();
  }




  static Future<void> clearWooCart(String token) async {
    await dotenv.load();
    const baseUrl = "https://www.aanahtar.com.tr";
    final response = await http.delete(
      Uri.parse('$baseUrl/wp-json/cocart/v2/cart/clear'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear WooCommerce cart: ${response.body}');
    }
  }

// Update WooCommerce Cart Item Quantity
  static Future<void> updateWooCartQuantity(String token, String productId, int quantity) async {
    await dotenv.load();
    const baseUrl = "https://www.aanahtar.com.tr";

    final bodyData = {
      'id': productId.toString(), // ✅ product ID as string
      'quantity': quantity.toString(), // ✅ quantity as string
    };

    print('📦 Sending to WooCommerce: ${jsonEncode(bodyData)}');

    final response = await http.post(
      Uri.parse('$baseUrl/wp-json/cocart/v2/cart/add-item'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode != 200) {
      print('❌ WooCommerce Error Response: ${response.body}');
      throw Exception('Failed to update WooCommerce cart: ${response.body}');
    } else {
      print('✅ Item updated successfully via add-item');
    }
  }

  static Future<void> setWooCartQuantity(
      String token,
      String cartItemKey,
      int quantity, {
        required int productId,
      }) async {
    await dotenv.load();
    const baseUrl = "https://www.aanahtar.com.tr";

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Attempt to update quantity via PUT
    final response = await http.put(
      Uri.parse('$baseUrl/wp-json/cocart/v2/cart/item/$cartItemKey'),
      headers: headers,
      body: jsonEncode({'quantity': quantity}),
    );

    if (response.statusCode == 200) {
      print('✅ PUT succeeded: quantity set to $quantity');
      return;
    }

    if (response.statusCode == 405 &&
        response.body.contains('cocart_item_restored_to_cart')) {
      print('⚠️ PUT failed due to restored item. Trying remove + re-add workaround...');

      // 🗑️ Step 1: Remove the item from cart
      final removeResponse = await http.delete(
        Uri.parse('$baseUrl/wp-json/cocart/v2/cart/item/$cartItemKey'),
        headers: headers,
      );

      if (removeResponse.statusCode != 200) {
        print('❌ Failed to remove item: ${removeResponse.body}');
        throw Exception('Failed to remove item before re-adding: ${removeResponse.body}');
      }

      // ➕ Step 2: Re-add with correct quantity
      final addResponse = await http.post(
        Uri.parse('$baseUrl/wp-json/cocart/v2/cart/add-item'),
        headers: headers,
        body: jsonEncode({
          'id': productId.toString(),
          'quantity': quantity.toString(),
        }),
      );

      if (addResponse.statusCode == 200) {
        print('✅ Fallback remove + re-add succeeded');
      } else {
        print('❌ Fallback re-add failed: ${addResponse.body}');
        throw Exception('Fallback re-add failed: ${addResponse.body}');
      }

      return;
    }

    print('❌ WooCommerce Error Response: ${response.body}');
    throw Exception('Failed to set WooCommerce cart quantity: ${response.body}');
  }
}
