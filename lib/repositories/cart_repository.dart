// lib/repositories/cart_repository.dart
//
// Replaces CartService's Woo Store API calls and the local guest cart.
//
// Two things differ from WooCommerce:
//   1. Line items are addressed by an INTEGER item id, not a string key.
//      Keep `CartItem.id` around — product_id won't work for update/remove.
//   2. Guests get a real server-side cart, identified by the X-Cart-Token
//      header. ApiClient stores and sends that automatically; on login the
//      server merges the guest basket into the customer's.
//
// Every endpoint returns the full cart, so there's no need to refetch after a
// mutation.

import '../services/api_client.dart';

class CartItem {
  /// The line id — use THIS for update and remove, not [productId].
  final int id;

  /// The product id — use this when ADDING.
  final int productId;

  final String name;
  final String? slug;
  final String? image;
  final int quantity;

  /// Null when prices are hidden (guest or unapproved account).
  final double? unitPrice;
  final double? lineTotal;

  final bool isPreorder;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.slug,
    required this.image,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.isPreorder,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        productId: (json['product_id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString(),
        image: json['image']?.toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unit_price'] as num?)?.toDouble(),
        lineTotal: (json['line_total'] as num?)?.toDouble(),
        isPreorder: json['is_preorder'] as bool? ?? false,
      );
}

class CartCoupon {
  final String code;
  final String? type;
  final String? label;

  const CartCoupon({required this.code, this.type, this.label});

  factory CartCoupon.fromJson(Map<String, dynamic> json) => CartCoupon(
        code: json['code']?.toString() ?? '',
        type: json['type']?.toString(),
        label: json['label']?.toString(),
      );
}

class Cart {
  final String? token;
  final bool priceVisible;
  final List<CartItem> items;
  final double? subtotal;
  final double? discount;
  final CartCoupon? coupon;
  final bool freeShipping;
  final bool hasPreorder;
  final String currencySymbol;

  const Cart({
    required this.token,
    required this.priceVisible,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.coupon,
    required this.freeShipping,
    required this.hasPreorder,
    required this.currencySymbol,
  });

  static const empty = Cart(
    token: null,
    priceVisible: false,
    items: [],
    subtotal: null,
    discount: null,
    coupon: null,
    freeShipping: false,
    hasPreorder: false,
    currencySymbol: '₺',
  );

  factory Cart.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as Map<String, dynamic>?;

    return Cart(
      token: json['token']?.toString(),
      priceVisible: json['price_visible'] as bool? ?? false,
      items: (json['items'] as List? ?? const [])
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      coupon: json['coupon'] is Map<String, dynamic>
          ? CartCoupon.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
      freeShipping: json['free_shipping'] as bool? ?? false,
      hasPreorder: json['has_preorder'] as bool? ?? false,
      currencySymbol: currency?['symbol']?.toString() ?? '₺',
    );
  }

  /// Total units, for the bottom-nav badge.
  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  String formatted(double? amount) =>
      amount == null ? '' : '$currencySymbol${amount.toStringAsFixed(2)}';
}

class CartRepository {
  final ApiClient _client;

  CartRepository(this._client);

  /// Fetches the cart.
  ///
  /// IMPORTANT: with no stored cart token the server CREATES a new cart row,
  /// so this returns an empty cart locally instead of calling out. Otherwise
  /// every app launch would leave an orphan cart in the database.
  Future<Cart> fetch() async {
    if (!_client.hasCartToken) return Cart.empty;

    final body = await _client.get('/cart');
    return Cart.fromJson(body as Map<String, dynamic>);
  }

  /// Fetches unconditionally — creating a cart if none exists. Use after login,
  /// when the server merges any guest basket into the customer's.
  Future<Cart> fetchOrCreate() async {
    final body = await _client.get('/cart');
    return Cart.fromJson(body as Map<String, dynamic>);
  }

  /// Adds by PRODUCT id. Adding a product that's already in the cart increases
  /// its quantity rather than creating a second line.
  Future<Cart> add(int productId, {int quantity = 1}) async {
    final body = await _client.post('/cart/items', {
      'product_id': productId,
      'quantity': quantity,
    });
    return Cart.fromJson(body as Map<String, dynamic>);
  }

  /// Sets an absolute quantity on a line. Pass 0 to delete it.
  /// [itemId] is CartItem.id — passing a product id gives a 404.
  Future<Cart> updateQuantity(int itemId, int quantity) async {
    final body = await _client.patch('/cart/items/$itemId', {
      'quantity': quantity,
    });
    return Cart.fromJson(body as Map<String, dynamic>);
  }

  Future<Cart> remove(int itemId) async {
    final body = await _client.delete('/cart/items/$itemId');
    return Cart.fromJson(body as Map<String, dynamic>);
  }

  /// Throws ApiException(422) with a Turkish message when the code is unknown,
  /// expired, or the cart is below the coupon's minimum.
  Future<Cart> applyCoupon(String code) async {
    final body = await _client.post('/cart/coupon', {'code': code.trim()});
    return Cart.fromJson(body as Map<String, dynamic>);
  }

  Future<Cart> removeCoupon() async {
    final body = await _client.delete('/cart/coupon');
    return Cart.fromJson(body as Map<String, dynamic>);
  }
}
