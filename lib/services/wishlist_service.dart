import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishListService {
  static const baseUrl = 'https://www.aanahtar.com.tr';

  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_currency') ?? 'TRY'; // Default to TRY
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return null;

    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['data']['user']['id'].toString();
      return userId;
    } catch (e) {
      print('Failed to decode token: $e');
      return null;
    }
  }

  static Future<List<int>> fetchUserWishlistIds() async {
    final token = await getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/wp-json/custom/v1/wishlist'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<int>.from(data);
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    await dotenv.load();
    final currency = await getSelectedCurrency();
    final locale = 'tr'; // Or get from provider if dynamic
    final apiBaseUrl = dotenv.env['API_BASE_URL_PRODUCTS']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    final url = Uri.parse(
      '$apiBaseUrl/$currency?include=${ids.join(",")}&consumer_key=$consumerKey&consumer_secret=$consumerSecret',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept-Language': locale,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cookie': 'woocommerce-currency=$currency',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Ürünler getirilemedi: ${response.body}');
    }
  }

  static Future<void> addToUserWishlist(int productId) async {
    print("TESTTTT");

    final token = await getToken();
    final userId = await getUserId(); // ✅ NOW STATIC

    print(token);
    print(userId);

    if (token == null || userId == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/wp-json/custom/v1/wishlist/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        'user_id': userId,
      }),
    );

    print('Add to wishlist response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Add to wishlist failed: ${response.body}');
    }
  }

  static Future<void> removeFromUserWishlist(int productId) async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/wp-json/custom/v1/wishlist/remove'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
      }),
    );
  }

  static Future<void> clearUserWishlist() async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/wp-json/custom/v1/wishlist/clear'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      print('Clear wishlist failed: ${response.body}');
      throw Exception('Failed to clear wishlist');
    } else {
      print('Clear wishlist response: ${response.body}');
    }
  }
}