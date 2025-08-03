import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wishlist_service.dart';

class WishlistProvider with ChangeNotifier {
  List<Map<String, dynamic>> _wishList = [];
  bool isLoading = false; // Correct name used consistently

  List<Map<String, dynamic>> get wishList => _wishList;

  bool isInWishlist(int productId) {
    return _wishList.any((item) => item['id'] == productId);
  }

  Future<void> loadWishlist() async {
    isLoading = true;
    notifyListeners();

    try {
      final token = await WishListService.getToken();
      if (token == null) {
        // Load guest wishlist from local storage
        await _loadGuestWishlist();
      } else {
        // 1. Fetch list of product IDs in user's wishlist
        final productIds = await WishListService.fetchUserWishlistIds();

        // 2. Fetch full product details from WooCommerce
        final data = await WishListService.fetchProductsByIds(productIds);

        // 3. Update local wishlist
        _wishList = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {

    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadGuestWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList('wishlist') ?? [];

    _wishList = stringList.map((item) => Map<String, dynamic>.from(jsonDecode(item))).toList();
  }

  Future<void> _saveGuestWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = _wishList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('wishlist', stringList);
  }

  Future<void> addToWishlist(Map<String, dynamic> product) async {
    if (!isInWishlist(product['id'])) {
      _wishList.add(product);

      final token = await WishListService.getToken();
      if (token != null) {
        // Logged-in user → sync with server
        await WishListService.addToUserWishlist(product['id']);
      } else {
        // Guest user → save JSON format
        final prefs = await SharedPreferences.getInstance();
        final List<String> stringList =
        _wishList.map((item) => jsonEncode(item)).toList();
        await prefs.setStringList('wishlist', stringList);
      }

      notifyListeners();
    }
  }

  Future<void> removeFromWishlist(int productId) async {
    _wishList.removeWhere((item) => item['id'] == productId);

    final token = await WishListService.getToken();
    if (token != null) {
      await WishListService.removeFromUserWishlist(productId);
    } else {
      await _saveGuestWishlist();
    }

    notifyListeners();
  }

  Future<void> toggleWishlist(Map<String, dynamic> product) async {
    if (isInWishlist(product['id'])) {
      await removeFromWishlist(product['id']);
    } else {
      await addToWishlist(product);
    }
  }

  Future<void> clearWishlist() async {
    _wishList.clear();
    notifyListeners();

    final token = await WishListService.getToken();
    if (token != null) {
      // Logged in user: clear wishlist from server
      await WishListService.clearUserWishlist();
    } else {
      // Guest user: clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wishlist');
    }
  }

  Future<void> syncGuestWishlistToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList('wishlist') ?? [];

    print("📌 Raw stored wishlist items: $stringList"); // Debugging

    List<Map<String, dynamic>> guestWishlist = [];

    for (var item in stringList) {
      try {
        // 🆕 Try JSON decoding first (new format)
        guestWishlist.add(Map<String, dynamic>.from(jsonDecode(item)));
      } catch (_) {
        try {
          // 🛠 Old format fallback: "{id: 123, title: Remote, price: 50}"
          final cleaned = item
              .replaceAll('{', '')
              .replaceAll('}', '')
              .split(',')
              .map((e) => e.split(':').map((s) => s.trim()).toList())
              .where((pair) => pair.length == 2)
              .map((pair) => MapEntry(pair[0], pair[1]))
              .toList();

          guestWishlist.add(Map<String, dynamic>.fromEntries(cleaned));
        } catch (e) {
          print("❌ Failed to parse wishlist item: $item → $e");
        }
      }
    }

    // ✅ Send each guest wishlist item to server
    for (var product in guestWishlist) {
      final id = product['id'] ?? product['productId'];
      if (id != null) {
        await WishListService.addToUserWishlist(int.tryParse(id.toString()) ?? 0);
      }
    }

    // ✅ Save wishlist in JSON format going forward
    final jsonList = guestWishlist.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('wishlist', jsonList);

    // ✅ Remove guest wishlist now that it's synced
    await prefs.remove('wishlist');

    // ✅ Reload from server
    await loadWishlist();
  }
}