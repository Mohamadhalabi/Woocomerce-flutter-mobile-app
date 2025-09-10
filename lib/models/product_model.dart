import 'brand_model.dart';

class ProductModel {
  final int id;
  final String title;
  final String image;
  final String category;
  final int? categoryId;
  final String sku;
  final double price;
  final double rating;
  final double? salePrice;
  final int? discountPercent;
  final Map<String, dynamic>? discount;
  final bool? freeShipping;
  final bool isNew;
  final bool isInStock;
  final List<String> images;
  final String description;
  final Map<String, List<String>> attributes;
  final String? currencySymbol;

  /// NEW: brands from API (YITH Brands)
  final List<BrandModel> brands;

  ProductModel({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.sku,
    required this.price,
    required this.rating,
    required this.images,
    required this.description,
    this.salePrice,
    this.discountPercent,
    this.discount,
    this.freeShipping,
    required this.isNew,
    required this.isInStock,
    required this.attributes,
    required this.currencySymbol,
    this.categoryId,
    this.brands = const [], // NEW
  });

  // ---------------- helpers ----------------
  static String? _stringOrNull(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num) return v.toString();
    return null;
  }

  static double _doubleOrZero(dynamic v) {
    final d = _doubleOrNull(v);
    return d ?? 0.0;
  }

  static double? _doubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString();
    if (s.trim().isEmpty) return null;
    return double.tryParse(s);
  }

  static bool? _boolFlexible(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == '1' || s == 'true' || s == 'yes') return true;
      if (s == '0' || s == 'false' || s == 'no') return false;
    }
    return null;
  }

  static String _resolveCurrencySymbol(dynamic currency, dynamic currencySymbol) {
    final code = _stringOrNull(currency)?.toUpperCase();
    if (code == 'USD') return '\$';
    if (code == 'TRY' || code == 'TL') return '₺';

    final sym = _stringOrNull(currencySymbol);
    return (sym != null && sym.isNotEmpty) ? sym : '₺';
  }
  // ------------------------------------------

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final createdDate =
        DateTime.tryParse(_stringOrNull(json['created_at']) ?? '') ??
            DateTime(2000);

    final List<dynamic> metaData =
    (json['meta_data'] is List) ? json['meta_data'] as List : const [];

    // attributes -> Map<String, List<String>>
    final Map<String, List<String>> attributeMap = {};
    if (json['attributes'] is List) {
      for (final attr in (json['attributes'] as List)) {
        if (attr is Map) {
          final name = _stringOrNull(attr['name']) ?? '';
          final opts = (attr['options'] is List) ? (attr['options'] as List) : const [];
          final values = opts
              .map((e) => _stringOrNull(e) ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
          attributeMap[name] = values;
        }
      }
    }

    // images
    final List<String> images =
    (json['images'] is List)
        ? (json['images'] as List)
        .where((e) => e is Map || e is String)
        .map((e) {
      if (e is Map) return _stringOrNull(e['src']) ?? '';
      return _stringOrNull(e) ?? '';
    })
        .where((s) => s.isNotEmpty)
        .toList()
        : <String>[];

    // category + categoryId
    String category = 'Uncategorized';
    int? categoryId;
    if (json['categories'] is List && (json['categories'] as List).isNotEmpty) {
      final first = (json['categories'] as List).first;
      if (first is Map) {
        category = _stringOrNull(first['name']) ?? category;
        if (first['id'] is int) {
          categoryId = first['id'] as int;
        } else {
          categoryId = int.tryParse(_stringOrNull(first['id']) ?? '');
        }
      }
    }

    // ---------- price logic ----------
    final reg = _doubleOrNull(json['regular_price']);
    final sale = _doubleOrNull(json['sale_price']);
    final woocs = _doubleOrNull(json['price']) ??
        _doubleOrNull(json['_price']) ??
        _doubleOrNull(json['display_price']);
    final resolvedRegular =
    (reg == null || reg == 0.0) ? (sale ?? woocs ?? 0.0) : reg;
    final parsedPrice = resolvedRegular;
    final parsedSalePrice = (sale != null && sale > 0) ? sale : null;

    // ---------- brands ----------
    final List<BrandModel> parsedBrands =
        (json['brands'] as List?)
            ?.map((e) => BrandModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
            .toList() ??
            const <BrandModel>[];

    return ProductModel(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(_stringOrNull(json['id']) ?? '0') ?? 0,
      title: _stringOrNull(json['name']) ?? 'No Title',
      image: images.isNotEmpty ? images.first : '',
      images: images,
      description: _stringOrNull(json['description']) ?? '',
      category: category,
      categoryId: categoryId,
      sku: _stringOrNull(json['sku']) ?? '',
      price: parsedPrice,
      salePrice: parsedSalePrice,
      discountPercent: (json['discount_percent'] is int)
          ? json['discount_percent'] as int
          : int.tryParse(_stringOrNull(json['discount_percent']) ?? ''),
      discount: (json['discount'] is Map<String, dynamic>)
          ? json['discount'] as Map<String, dynamic>
          : null,
      freeShipping: _boolFlexible(json['free_shipping']),
      isNew: checkIsNewFromMetaData(metaData) ||
          createdDate.isAfter(DateTime.now().subtract(const Duration(days: 30))),
      rating: _doubleOrZero(json['average_rating']),
      attributes: attributeMap,
      isInStock: _stringOrNull(json['stock_status']) == 'instock',
      currencySymbol:
      _resolveCurrencySymbol(json['currency'], json['currency_symbol']),
      brands: parsedBrands, // NEW
    );
  }

  static bool checkIsNewFromMetaData(List<dynamic> metaData) {
    for (final item in metaData) {
      if (item is Map &&
          item['key'] == '_yith_wcbm_badges' &&
          item['value'] is List &&
          (item['value'] as List).isNotEmpty) {
        final first = (item['value'] as List).first;
        final badgeText =
        (first is Map) ? _stringOrNull(first['text'])?.toLowerCase() ?? '' : '';
        if (badgeText.contains('yeni')) return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'category': category,
      'category_id': categoryId,
      'sku': sku,
      'price': price,
      'sale_price': salePrice,
      'discount_percent': discountPercent,
      'discount': discount,
      'free_shipping': freeShipping,
      'is_best_seller': isNew,
      'gallery': images,
      'description': description,
      'rating': rating,
      'num_of_reviews': 0,
      'attributes': attributes,
      'stock_status': isInStock ? 'instock' : 'outofstock',
      'currency_symbol': currencySymbol ?? '₺',
      // NEW: expose brands so your UI can read product?['brands']
      'brands': brands.map((b) => b.toJson()).toList(),
    };
  }
}

// (optional) helpers for UI
extension ProductPriceX on ProductModel {
  double get displayPrice =>
      (salePrice != null && salePrice! > 0) ? salePrice! : price;

  bool get hasDiscount =>
      (salePrice != null && salePrice! > 0 && salePrice! < price);
}
