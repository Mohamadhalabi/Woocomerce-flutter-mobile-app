// lib/repositories/account_repository.dart
//
// GET/PUT /account/address, GET /account/orders, GET /account/orders/{number}.
//
// Two shape traps worth knowing:
//   - The order LIST is a raw Laravel paginator: {data, current_page, ...} at
//     the top level, no `data` wrapper around the whole thing.
//   - The order DETAIL is {order: {...}, items: [...]} — also no `data` key.
//     Reading jsonResponse['data'] on it returns null.
//
// Orders are fetched by ORDER NUMBER (AA-100123), not by id.

import '../services/api_client.dart';

/// One address per customer — the schema holds no more than that, which is
/// why there's no address book here.
class AddressModel {
  final String? address;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  const AddressModel({
    this.address,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    address: _s(json['address']),
    city: _s(json['city']),
    state: _s(json['state']),
    postcode: _s(json['postcode']),
    country: _s(json['country']),
  );

  Map<String, dynamic> toJson() => {
    'address': address,
    'city': city,
    'state': state,
    'postcode': postcode,
    'country': country,
  };

  bool get isEmpty =>
      (address ?? '').isEmpty &&
          (city ?? '').isEmpty &&
          (postcode ?? '').isEmpty;

  static String? _s(dynamic v) {
    final str = v?.toString().trim();
    return (str == null || str.isEmpty) ? null : str;
  }
}

class OrderSummary {
  final int id;
  final String orderNumber;

  /// Raw key: pending, on_hold, processing, shipped, completed, cancelled,
  /// refunded. The API doesn't send a label, so [statusLabel] maps it here.
  final String status;

  final double total;
  final String currencyCode;
  final DateTime? createdAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.currencyCode,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: (json['id'] as num?)?.toInt() ?? 0,
    orderNumber: json['order_number']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    total: (json['total'] as num?)?.toDouble() ?? 0,
    currencyCode: json['currency_code']?.toString() ?? 'TRY',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );

  /// Duplicated from Order::STATUSES on the server. Ask the backend to add
  /// `status_label` to orderSummary() and this can be deleted.
  static const _labels = {
    'pending': 'Beklemede',
    'on_hold': 'Beklemede',
    'processing': 'Hazırlanıyor',
    'shipped': 'Kargolandı',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal Edildi',
    'refunded': 'İade Edildi',
  };

  String get statusLabel => _labels[status] ?? status;

  String get currencySymbol {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '₺';
    }
  }

  String get formattedTotal => '$currencySymbol${total.toStringAsFixed(2)}';
}

class OrderLine {
  final int id;
  final String title;
  final String? sku;
  final String? thumb;
  final String? slug;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const OrderLine({
    required this.id,
    required this.title,
    required this.sku,
    required this.thumb,
    required this.slug,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    id: (json['id'] as num?)?.toInt() ?? 0,
    // Lines keep their own snapshot, so a deleted product still reads
    // correctly — only the thumbnail goes missing.
    title: json['product_title']?.toString() ?? '',
    sku: json['product_sku']?.toString(),
    thumb: json['thumb']?.toString(),
    slug: json['slug']?.toString(),
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
  );
}

class OrderDetail {
  final OrderSummary summary;
  final double subtotal;
  final double discount;
  final double tax;
  final double shippingCost;
  final String? paymentMethod;
  final String? couponCode;
  final String? notes;

  final String? customerName;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? postcode;

  final List<OrderLine> items;

  const OrderDetail({
    required this.summary,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shippingCost,
    required this.paymentMethod,
    required this.couponCode,
    required this.notes,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.postcode,
    required this.items,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final order = (json['order'] as Map<String, dynamic>?) ?? const {};
    final billing = (order['billing'] as Map<String, dynamic>?) ?? const {};

    return OrderDetail(
      summary: OrderSummary.fromJson(order),
      subtotal: (order['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (order['discount'] as num?)?.toDouble() ?? 0,
      tax: (order['tax'] as num?)?.toDouble() ?? 0,
      shippingCost: (order['shipping_cost'] as num?)?.toDouble() ?? 0,
      paymentMethod: order['payment_method']?.toString(),
      couponCode: order['coupon_code']?.toString(),
      notes: order['notes']?.toString(),
      customerName: billing['name']?.toString(),
      phone: billing['phone']?.toString(),
      address: billing['address']?.toString(),
      city: billing['city']?.toString(),
      state: billing['state']?.toString(),
      postcode: billing['postcode']?.toString(),
      items: (json['items'] as List? ?? const [])
          .map((i) => OrderLine.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderPage {
  final List<OrderSummary> orders;
  final int currentPage;
  final int lastPage;
  final int total;

  const OrderPage({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory OrderPage.fromJson(Map<String, dynamic> json) => OrderPage(
    orders: (json['data'] as List? ?? const [])
        .map((o) => OrderSummary.fromJson(o as Map<String, dynamic>))
        .toList(),
    // Raw paginator: these sit at the TOP level, not under `meta`.
    currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
    lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  bool get hasMore => currentPage < lastPage;
}

class Currency {
  final String code;
  final String symbol;
  final String? name;

  const Currency({required this.code, required this.symbol, this.name});

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    code: json['code']?.toString() ?? '',
    symbol: json['symbol']?.toString() ?? '',
    name: json['name']?.toString(),
  );
}

class AccountRepository {
  final ApiClient _client;

  AccountRepository(this._client);

  // ── Address ─────────────────────────────────────────────────────────────

  Future<AddressModel> address() async {
    final body = await _client.get('/account/address');
    final data =
    (body as Map<String, dynamic>)['address'] as Map<String, dynamic>?;
    return AddressModel.fromJson(data ?? const {});
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    final body = await _client.put('/account/address', address.toJson());
    final data =
    (body as Map<String, dynamic>)['address'] as Map<String, dynamic>?;
    return AddressModel.fromJson(data ?? address.toJson());
  }

  // ── Orders ──────────────────────────────────────────────────────────────

  Future<OrderPage> orders({int page = 1}) async {
    final body = await _client.get('/account/orders', query: {'page': page});
    return OrderPage.fromJson(body as Map<String, dynamic>);
  }

  /// [number] is the order NUMBER (AA-100123), not the id. Other people's
  /// orders 404 rather than 403.
  Future<OrderDetail> order(String number) async {
    final body = await _client.get('/account/orders/$number');
    return OrderDetail.fromJson(body as Map<String, dynamic>);
  }

  /// Polled after the payment WebView closes.
  ///
  /// The WebView closing proves nothing — the customer may have dismissed it
  /// mid-payment, and iyzico's callback is what actually settles the order.
  /// This is the only source of truth.
  Future<String> paymentStatus(String orderNumber) async {
    final body = await _client.get('/orders/$orderNumber/payment-status');
    return (body as Map<String, dynamic>)['payment_status']?.toString() ??
        'unpaid';
  }

  // ── Currencies ──────────────────────────────────────────────────────────

  /// The options for the header switcher. Every other endpoint reads the
  /// choice from the X-Currency header.
  Future<List<Currency>> currencies() async {
    final body = await _client.get('/currencies');

    final list = body is List
        ? body
        : (body as Map<String, dynamic>)['data'] as List? ?? const [];

    return list
        .map((c) => Currency.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}