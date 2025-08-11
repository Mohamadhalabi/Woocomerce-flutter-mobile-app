import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';
import 'cart_service.dart';

class ApiService {

  // set Turkish lira default Currency
  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_currency') ?? 'TRY'; // Default to TRY
  }
  // Home Page API
  static Future<List<CategoryModel>> fetchCategories(String locale) async {
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL'];
    final consumerKey = dotenv.env['CONSUMER_KEY'];
    final consumerSecret = dotenv.env['CONSUMER_SECRET'];

    final url = Uri.parse(
        '$baseUrl/products/categories?consumer_key=$consumerKey&consumer_secret=$consumerSecret&per_page=100'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Kategori alınamadı: ${response.body}');
    }
  }

  static Future<List<ProductModel>> fetchLatestProducts(String locale) async {
    final currency = await getSelectedCurrency();
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL_PRODUCTS'] ?? '';
      String consumerKey = dotenv.env['CONSUMER_KEY'] ?? '';
      String consumerSecret = dotenv.env['CONSUMER_SECRET'] ?? '';

      String url =
          '$apiBaseUrl/$currency?per_page=12&order=desc&orderby=date&status=publish&consumer_key=$consumerKey&consumer_secret=$consumerSecret&currency=$currency';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'woocommerce-currency=$currency',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => ProductModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load latest products: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<List<ProductModel>> fetchEmulatorProducts(String locale) async {
    final currency = await getSelectedCurrency();
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL_PRODUCTS'] ?? '';
      String consumerKey = dotenv.env['CONSUMER_KEY'] ?? '';
      String consumerSecret = dotenv.env['CONSUMER_SECRET'] ?? '';

      // Fetch latest 12 published products, ordered by date descending
      String url =
          '$apiBaseUrl/$currency?per_page=12&order=desc&orderby=date&status=publish'
          '&category=62'
          '&consumer_key=$consumerKey'
          '&consumer_secret=$consumerSecret';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'woocommerce-currency=$currency',
        },
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => ProductModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load Emulator products: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<List<Map<String, String>>> fetchSliders(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/get-sliders?type=banner';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': await getSelectedCurrency(),
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          return jsonResponse.map<Map<String, String>>((item) {
            return {
              'image': item['image'].toString(),
              'link': item['link'].toString(),
            };
          }).toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Failed to load sliders");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }


  static Future<List<ProductModel>> fetchFlashSaleProducts(String locale) async {
    final currency = await getSelectedCurrency();

    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL_PRODUCTS'] ?? '';
    String consumerKey = dotenv.env['CONSUMER_KEY'] ?? '';
    String consumerSecret = dotenv.env['CONSUMER_SECRET'] ?? '';

    final url = Uri.parse('$apiBaseUrl/$currency?on_sale=true&per_page=12&consumer_key=$consumerKey&consumer_secret=$consumerSecret');

    final response = await http.get(
      url,
      headers: {
        'Accept-Language': locale,
        'Content-Type': 'application/json',
        'currency': await getSelectedCurrency(),
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load flash sale products: ${response.body}");
    }
  }

  static Future<List<ProductModel>> fetchBundleProducts(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/products/bundle-products';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': await getSelectedCurrency(),
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['bundle_products'] != null &&
            jsonResponse['bundle_products'] is List) {
          return (jsonResponse['bundle_products'] as List)
              .map((item) => ProductModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Invalid API response format for bundle_products");
        }
      } else {
        throw Exception("Failed to load Bundle products");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
  // product details
  static Future<ProductModel> fetchProductById(int id, String locale) async {
    final currency = await getSelectedCurrency();
    await dotenv.load();
    final baseUrl = dotenv.env['API_BASE_URL_PRODUCTS']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;
    final url = Uri.parse(
      '$baseUrl/$currency?product_id=$id&consumer_key=$consumerKey&consumer_secret=$consumerSecret',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Accept-Language': locale,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return ProductModel.fromJson(data);
    } else {
      throw Exception('Failed to load product: ${response.statusCode}');
    }
  }

  // fetch card product by id

  static Future<ProductModel> fetchProductCardById(int id, String locale) async {
    final currency = await getSelectedCurrency();
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL_PRODUCTS']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    final url = Uri.parse(
      '$baseUrl/$currency?product_id=$id&consumer_key=$consumerKey&consumer_secret=$consumerSecret&context=card',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Accept-Language': locale,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductModel.fromJson(data);
    } else {
      throw Exception('Failed to load product card: ${response.statusCode}');
    }
  }

  static Future<List<ProductModel>> fetchProductsCardByIds(
      List<int> ids, String locale) async {
    if (ids.isEmpty) return [];

    final currency = await getSelectedCurrency();
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL_PRODUCTS']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    final url = Uri.parse(
      '$baseUrl/$currency?include=${ids.join(',')}&consumer_key=$consumerKey&consumer_secret=$consumerSecret&context=card',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Accept-Language': locale,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  // update user info
  static Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? password,
  }) async {
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse(
      "$baseUrl/customers/me"
          "?consumer_key=$consumerKey"
          "&consumer_secret=$consumerSecret",
    );

    final body = {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "billing": {
        "phone": phone,
      },
      if (password != null && password.isNotEmpty) "password": password,
    };

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update profile: ${response.body}");
    }
  }
  // update user address
  static Future<void> updateUserAddress({
    required String address1,
    required String city,
    required String state,
    required String postcode,
  }) async {
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('Not authenticated');

    // 1️⃣ Get the current user data so we don't wipe it
    final currentUser = await ApiService.fetchUserInfo();

    final url = Uri.parse(
      "$baseUrl/customers/me?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    // 2️⃣ Merge the new address fields with existing info
    final body = {
      "first_name": currentUser['first_name'] ?? "",
      "last_name": currentUser['last_name'] ?? "",
      "email": currentUser['email'] ?? "",
      "phone": currentUser['phone'] ?? "222",
      "billing": {
        "first_name": currentUser['billing']?['first_name'] ?? currentUser['first_name'] ?? "",
        "last_name": currentUser['billing']?['last_name'] ?? currentUser['last_name'] ?? "",
        "email": currentUser['billing']?['email'] ?? currentUser['email'] ?? "",
        "billing_phone": currentUser['billing']?['phone'] ?? "",
        "address_1": address1,
        "city": city,
        "state": state,
        "postcode": postcode,
        "country": currentUser['billing']?['country'] ?? "TR",
      },
      "shipping": {
        "first_name": currentUser['shipping']?['first_name'] ?? currentUser['first_name'] ?? "",
        "last_name": currentUser['shipping']?['last_name'] ?? currentUser['last_name'] ?? "",
        "address_1": address1,
        "city": city,
        "state": state,
        "postcode": postcode,
        "country": currentUser['shipping']?['country'] ?? "TR",
      }
    };

    // 3️⃣ Send the full payload so Woo doesn't wipe fields
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update address: ${response.body}");
    }
  }

  static Future<List<ProductModel>> fetchRelatedProductsWoo(String locale, int productId) async {
    final currency = await getSelectedCurrency();
    await dotenv.load();
    final baseUrl = dotenv.env['API_BASE_URL_PRODUCTS']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    try {
      // 1) Get main product (shape can be object OR [object])
      final productUrl =
          '$baseUrl/$currency?product_id=$productId&consumer_key=$consumerKey&consumer_secret=$consumerSecret';

      final productRes = await http.get(
        Uri.parse(productUrl),
        headers: {
          'Accept-Language': locale,
          'Accept': 'application/json',
          'Cookie': 'woocommerce-currency=$currency',
        },
      );
      if (productRes.statusCode != 200) {
        throw Exception('Product fetch failed (${productRes.statusCode})');
      }

      final decoded = json.decode(productRes.body);
      final Map<String, dynamic> productJson =
      (decoded is List && decoded.isNotEmpty) ? Map<String, dynamic>.from(decoded.first)
          : Map<String, dynamic>.from(decoded as Map);

      final List<dynamic> relatedIdsDyn = productJson['related_ids'] is List ? productJson['related_ids'] : const [];
      final List<int> relatedIds = relatedIdsDyn
          .map((e) => e is int ? e : int.tryParse('$e'))
          .whereType<int>()
          .toList();

      if (relatedIds.isEmpty) return [];

      // 2) Fetch related products (limit 5)
      final relatedUrl =
          '$baseUrl/$currency?include=${relatedIds.join(",")}&orderby=date&order=desc&per_page=5&consumer_key=$consumerKey&consumer_secret=$consumerSecret';

      final relatedRes = await http.get(
        Uri.parse(relatedUrl),
        headers: {
          'Accept-Language': locale,
          'Accept': 'application/json',
          'Cookie': 'woocommerce-currency=$currency',
        },
      );
      if (relatedRes.statusCode != 200) {
        throw Exception('Related fetch failed (${relatedRes.statusCode})');
      }

      final relatedJson = json.decode(relatedRes.body);
      final List list = relatedJson is List ? relatedJson : [];
      return list.map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p))).toList();
    } catch (e) {
      throw Exception("Woo Related Error: $e");
    }
  }

  // login function
  static Future<String> loginUserWithEmail({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('https://www.aanahtar.com.tr/wp-json/jwt-auth/v1/token');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 403 && response.body.contains('not approved')) {
      throw Exception('Hesabınız henüz onaylanmadı.');
    }

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['token'];
    }

    // ❗️ Non-200: parse and throw a clean message
    try {
      final data = jsonDecode(response.body);
      final code = (data['code'] ?? '').toString();
      final msg  = (data['message'] ?? '').toString();

      // Optional: map known codes to Turkish messages
      final mapped = _mapJwtError(code, msg);
      throw Exception(mapped);
    } catch (_) {
      throw Exception('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.');
    }
  }

// Map common JWT/WP codes to friendly TR messages
  static String _mapJwtError(String code, String fallback) {
    switch (code) {
      case 'jwt_auth_invalid_email':
      case 'invalid_email':
        return 'Geçersiz e-posta adresi.';
      case 'jwt_auth_invalid_username':
      case 'invalid_username':
        return 'Geçersiz kullanıcı adı.';
      case 'jwt_auth_incorrect_password':
        return 'Parola hatalı. Lütfen tekrar deneyin.';
      case 'jwt_user_not_found':
        return 'Kullanıcı bulunamadı.';
      case 'jwt_auth':
        return 'Giriş yapılamadı. Bilgilerinizi kontrol edin.';
      default:
        return fallback.isNotEmpty ? fallback : 'Giriş yapılamadı.';
    }
  }
  // check if the user is LoggeIn

  //login with phone
  static Future<void> sendLoginCode(String phone) async {
    final response = await http.post(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/custom-auth/v1/request-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone}),
    );

    final json = jsonDecode(response.body);
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Kod gönderilemedi');
    }
  }

  static Future<Map<String, dynamic>> verifyLoginCode({
    required String phone,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/custom-auth/v1/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone, 'code': code}),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode != 200 || json['token'] == null) {
      throw Exception(json['message'] ?? 'Doğrulama başarısız');
    }

    return json;
  }

  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> billing,
    required Map<String, dynamic> shipping,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id'); // Saved at login
    final baseUrl = "https://www.aanahtar.com.tr/wp-json/wc/v3";
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    // 🔹 Build line items with TRY prices
    final lineItems = cartItems.map((item) {
      double price = 0.0;
      if (item['price'] is num) {
        price = (item['price'] as num).toDouble();
      } else if (item['price'] is String) {
        price = double.tryParse(item['price']) ?? 0.0;
      }
      int qty = int.tryParse(item['quantity'].toString()) ?? 1;

      // Calculate totals
      final subtotal = price * qty;
      final total = subtotal;

      return {
        "product_id": item['product_id'] ?? item['id'],
        "quantity": qty,
        "subtotal": subtotal.toStringAsFixed(2),
        "total": total.toStringAsFixed(2),
      };
    }).toList();

    final orderData = {
      "customer_id": userId,
      "payment_method": "bacs",
      "payment_method_title": "Banka Havalesi",
      "set_paid": false,
      "billing": billing,
      "shipping": shipping,
      "line_items": lineItems,
      "currency": "TRY"
    };

    print("📦 Order Data: $orderData");

    final response = await http.post(
      Uri.parse("$baseUrl/orders"
          "?consumer_key=$consumerKey"
          "&consumer_secret=$consumerSecret"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(orderData),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(json['message'] ?? 'Sipariş oluşturulamadı.');
    }

    return json;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  //fetch user info
  static Future<Map<String, dynamic>> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("Kullanıcı girişi yapılmamış.");
    }

    const url = 'https://www.aanahtar.com.tr/wp-json/custom-auth/v1/user-info';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Kullanıcı bilgileri alınamadı: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> fetchUserBilling() async {
    await dotenv.load(); // ✅ Load .env

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id'); // Save this at login

    if (userId == null) {
      throw Exception("Not logged in");
    }

    final consumerKey = dotenv.env['CONSUMER_KEY'] ?? '';
    final consumerSecret = dotenv.env['CONSUMER_SECRET'] ?? '';

    if (consumerKey.isEmpty || consumerSecret.isEmpty) {
      throw Exception("WooCommerce API keys are missing from .env");
    }

    final url = Uri.parse(
      'https://www.aanahtar.com.tr/wp-json/wc/v3/customers/$userId'
          '?consumer_key=$consumerKey&consumer_secret=$consumerSecret',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch billing: ${response.body}");
    }
  }
  // fetch order history

  static Future<List<Map<String, dynamic>>> fetchUserOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("Kullanıcı girişi yapılmamış.");
    }

    // 1️⃣ Get user ID first
    final userResponse = await http.get(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/wp/v2/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (userResponse.statusCode != 200) {
      throw Exception('Kullanıcı bilgileri alınamadı: ${userResponse.body}');
    }

    final userData = jsonDecode(userResponse.body);
    final userId = userData['id'];

    print(userId);

    // 2️⃣ Fetch orders for that user & force TRY
    final ordersUrl = Uri.parse(
        'https://www.aanahtar.com.tr/wp-json/wc/v3/orders?customer=$userId&status=any&currency=TRY'
    );



    final ordersResponse = await http.get(
      ordersUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (ordersResponse.statusCode == 200) {

      print(jsonDecode(ordersResponse.body));

      return List<Map<String, dynamic>>.from(jsonDecode(ordersResponse.body));
    } else {
      throw Exception('Siparişler alınamadı: ${ordersResponse.body}');
    }
  }

  static Future<void> registerUser({
    String? email,
    String? password,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/custom-auth/v1/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email?.isNotEmpty == true ? email : null,
        'password': password?.isNotEmpty == true ? password : null,
        'phone': phone,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Kayıt başarısız');
    }
  }
  //register with phone
  static Future<void> registerWithPhone({
    required String phone,
    String? email,
    String? password,
  }) async {
    // Step 1: Register the user
    final registerResponse = await http.post(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/custom-auth/v1/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
      }),
    );

    final registerJson = jsonDecode(registerResponse.body);
    if (registerResponse.statusCode != 200 || registerJson['success'] != true) {
      throw Exception(registerJson['message'] ?? 'Kayıt başarısız');
    }

    // Step 2: Send login/verification code via WhatsApp
    final codeResponse = await http.post(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/custom-auth/v1/request-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone}),
    );

    final codeJson = jsonDecode(codeResponse.body);
    if (codeResponse.statusCode != 200 || codeJson['success'] != true) {
      throw Exception(codeJson['message'] ?? 'Kod gönderilemedi');
    }
  }


  //update profile name

  static Future<void> updateProfileName({
    required String token,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http.post(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/custom-auth/v1/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
      }),
    );

    final json = jsonDecode(response.body);
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Profil güncellenemedi');
    }
  }

  static Future<Map<String, List<String>>> fetchFiltersForEntry({
    required int id,
    required String filterType, // 'category', 'brand', or 'manufacturer'
  }) async {
    final url = Uri.parse(
      'https://www.aanahtar.com.tr/wp-json/custom/v1/attributes-for-filter?filterType=$filterType&id=$id',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final result = <String, List<String>>{};

      for (var item in data) {
        final String taxonomy = item['taxonomy'];
        final List<String> terms = List<String>.from(
          (item['terms'] as List).map((e) => e['name'].toString()),
        );
        result[taxonomy] = terms;
      }

      return result;
    } else {
      throw Exception('Failed to fetch filters: ${response.body}');
    }
  }


  static Future<List<ProductModel>> fetchFilteredProducts({
    required int id,
    required String filterType,
    required int page,
    required int perPage,
    required Map<String, List<String>> selectedFilters,
    String sort = 'new_to_old',
    bool onSale = false, // ✅ New param
  }) async {
    final currency = await getSelectedCurrency();

    String orderBy = 'date';
    String order = 'desc';

    switch (sort) {
      case 'old_to_new':
        order = 'asc';
        break;
      case 'price_asc':
        orderBy = 'price';
        order = 'asc';
        break;
      case 'price_desc':
        orderBy = 'price';
        order = 'desc';
        break;
    }

    final filtersJson = jsonEncode(selectedFilters);

    String url =
        'https://www.aanahtar.com.tr/wp-json/woocs/v3/products/$currency'
        '?${filterType.toLowerCase()}=$id'
        '&page=$page'
        '&per_page=$perPage'
        '&orderby=$orderBy'
        '&order=$order'
        '&attributes=${Uri.encodeComponent(filtersJson)}';

    if (onSale) {
      url += '&on_sale=true'; // ✅ Add this
    }

    final uri = Uri.parse(url);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch filtered products: ${response.body}');
    }
  }

  // static Future<List<ProductModel>> fetchFilteredProducts({
  //   required int id,
  //   required String filterType,
  //   required int page,
  //   required int perPage,
  //   required Map<String, List<String>> selectedFilters,
  //   String sort = '',
  //   String currency = 'TRY',
  // }) async {
  //   final filtersJson = jsonEncode(selectedFilters);
  //
  //   // ✅ Map sort key to API-compatible query param
  //   String orderBy = 'date';
  //   String order = 'desc';
  //
  //   switch (sort) {
  //     case 'old_to_new':
  //       orderBy = 'date';
  //       order = 'asc';
  //       break;
  //     case 'price_asc':
  //       orderBy = 'price';
  //       order = 'asc';
  //       break;
  //     case 'price_desc':
  //       orderBy = 'price';
  //       order = 'desc';
  //       break;
  //     case 'new_to_old':
  //     default:
  //       orderBy = 'date';
  //       order = 'desc';
  //   }
  //
  //   final url = Uri.parse(
  //       'https://www.aanahtar.com.tr/wp-json/custom/v1/filtered-products'
  //           '?filterType=$filterType'
  //           '&id=$id'
  //           '&page=$page'
  //           '&per_page=$perPage'
  //           '&orderby=$orderBy'
  //           '&order=$order'
  //           '&attributes=${Uri.encodeComponent(filtersJson)}'
  //           '&currency=$currency'
  //   );
  //
  //
  //   final response = await http.get(url);
  //
  //   if (response.statusCode == 200) {
  //     final List data = jsonDecode(response.body);
  //     return data.map((json) => ProductModel.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to fetch filtered products: ${response.body}');
  //   }
  // }



  //search
  static Future<List<ProductModel>> fetchProductsBySearch({
    required String search,
    required String locale,
    int page = 1,
    int perPage = 8,
  }) async {
    await dotenv.load();
    final baseUrl = dotenv.env['API_BASE_URL'];
    final key = dotenv.env['CONSUMER_KEY'];
    final secret = dotenv.env['CONSUMER_SECRET'];

    final url = Uri.parse(
      '$baseUrl/products?search=${Uri.encodeComponent(search)}'
          '&page=$page&per_page=$perPage'
          '&consumer_key=$key&consumer_secret=$secret'
          '&lang=$locale',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      return jsonData.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search products');
    }
  }

  // brands and manufacturers fetch
  static Future<Map<String, dynamic>> fetchDrawerData(String lang) async {
    await dotenv.load();
    final baseUrl = dotenv.env['API_BASE_URL'];

    final response = await http.get(Uri.parse('$baseUrl/custom/v1/drawer-data?lang=$lang'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Return Map<String, dynamic>
    } else {
      throw Exception('Failed to fetch drawer data');
    }
  }

  //fetch order details
  static Future<Map<String, dynamic>> fetchOrderDetails(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("Kullanıcı girişi yapılmamış.");
    }

    final url = Uri.parse("https://www.aanahtar.com.tr/wp-json/wc/v3/orders/$orderId");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Sipariş detayları alınamadı: ${response.body}');
    }
  }


}