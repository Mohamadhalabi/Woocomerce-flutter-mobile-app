import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';

class ApiService {

  // set Turkish lira default Currency
  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_currency') ?? 'TRY'; // Default to TRY
  }
  static Future<Map<String, String>> _buildHeaders(String locale, String apiKey, String secretKey) async {
    return {
      'Accept-Language': locale,
      'Content-Type': 'application/json',
      'currency': await getSelectedCurrency(),
      'Accept': 'application/json',
      'secret-key': secretKey,
      'api-key': apiKey,
    };
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


    print("fetching sale products!!!!!!!!");

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

  static Future<List<ProductModel>> fetchRelatedProductsWoo(String locale, int productId) async {
    final currency = await getSelectedCurrency();
    await dotenv.load(); // Make sure this is included if not already called
    final baseUrl = dotenv.env['API_BASE_URL_PRODUCTS']!;
    final consumerKey = dotenv.env['CONSUMER_KEY']!;
    final consumerSecret = dotenv.env['CONSUMER_SECRET']!;

    try {
      // 1. Fetch main product to get related_ids
      final productUrl = '$baseUrl/$currency?product_id=$productId&consumer_key=$consumerKey&consumer_secret=$consumerSecret';
      final productRes = await http.get(
        Uri.parse(productUrl),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'woocommerce-currency=$currency',
        },
      );

      if (productRes.statusCode != 200) throw Exception('Product fetch failed');

      final productJson = json.decode(productRes.body);
      List relatedIds = productJson['related_ids'] ?? [];

      if (relatedIds.isEmpty) return [];

      // 2. Fetch related products by IDs
      final relatedUrl = '$baseUrl/$currency?include=${relatedIds.join(",")}&orderby=date&order=desc&per_page=5&consumer_key=$consumerKey&consumer_secret=$consumerSecret';
      final relatedRes = await http.get(
        Uri.parse(relatedUrl),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'woocommerce-currency=$currency',
        },
      );

      if (relatedRes.statusCode != 200) throw Exception('Related fetch failed');

      final relatedJson = json.decode(relatedRes.body) as List;
      return relatedJson.map((p) => ProductModel.fromJson(p)).toList();
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
      // User registered but not yet approved
      throw Exception('Hesabınız henüz onaylanmadı.');
    }
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['token']; // ✅ returns token
    } else {
      throw Exception('Login Error: ${response.body}');
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

    const url = 'https://www.aanahtar.com.tr/wp-json/wp/v2/users/me';

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
  // fetch order history

  static Future<List<Map<String, dynamic>>> fetchUserOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("Kullanıcı girişi yapılmamış.");
    }

    // Step 1: Get user ID first
    final userResponse = await http.get(
      Uri.parse('https://www.aanahtar.com.tr/wp-json/wp/v2/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (userResponse.statusCode != 200) {
      throw Exception('Kullanıcı bilgileri alınamadı: ${userResponse.body}');
    }

    final userData = jsonDecode(userResponse.body);
    final userId = userData['id'];

    // Step 2: Fetch orders for that user
    final ordersUrl = Uri.parse(
      'https://www.aanahtar.com.tr/wp-json/wc/v3/orders?customer=$userId',
    );

    final ordersResponse = await http.get(
      ordersUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (ordersResponse.statusCode == 200) {
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

  //fetch products by category
  static Future<List<ProductModel>> fetchProductsByCategory({
    required int categoryId,
    required String locale,
    int page = 1,
    int perPage = 16,
    String? search,
    Map<String, List<String>> selectedFilters = const {},
  }) async {
    await dotenv.load();
    final baseUrl = dotenv.env['API_BASE_URL'];
    final key = dotenv.env['CONSUMER_KEY'];
    final secret = dotenv.env['CONSUMER_SECRET'];

    final query = StringBuffer()
      ..write('category=$categoryId')
      ..write('&page=$page')
      ..write('&per_page=$perPage')
      ..write('&consumer_key=$key')
      ..write('&consumer_secret=$secret')
      ..write('&lang=$locale');

    if (search != null && search.isNotEmpty) {
      query.write('&search=${Uri.encodeComponent(search)}');
    }

    // Encode attribute filters
    if (selectedFilters.isNotEmpty) {
      for (var entry in selectedFilters.entries) {
        for (var term in entry.value) {
          query.write('&attribute=${entry.key}&attribute_term=${Uri.encodeComponent(term)}');
        }
      }
    }

    final url = Uri.parse('$baseUrl/products?$query');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      return jsonData.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load filtered category products');
    }
  }


  static Future<Map<String, List<String>>> fetchFiltersForCategory(int categoryId) async {
    final url = Uri.parse('https://www.aanahtar.com.tr/wp-json/custom/v1/attributes-for-category?category=$categoryId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((key, value) {
        final terms = List<String>.from(value.map((e) => e.toString()));
        return MapEntry(key, terms);
      });
    } else {
      throw Exception('Failed to fetch filters: ${response.body}');
    }
  }

  static Future<List<ProductModel>> fetchFilteredProducts({
    required int categoryId,
    required int page,
    required int perPage,
    required Map<String, List<String>> selectedFilters,
  }) async {
    final filtersJson = jsonEncode(selectedFilters);
    final url = Uri.parse(
      'https://www.aanahtar.com.tr/wp-json/custom/v1/filtered-products'
          '?category=$categoryId&page=$page&per_page=$perPage&attributes=${Uri.encodeComponent(filtersJson)}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load filtered products: ${response.body}');
    }
  }


  //search
  static Future<List<ProductModel>> fetchProductsBySearch({
    required String search,
    required String locale,
    int page = 1,
    int perPage = 16,
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

}