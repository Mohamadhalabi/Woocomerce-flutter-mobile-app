// lib/models/catalog_product.dart
//
// Two shapes, because the API has two resources:
//   ProductModel  -> ProductCardResource  (lists, home, related, suggest)
//   ProductDetail -> ProductDetailResource (/products/{slug})
//
// The big change from the WooCommerce models: prices are NULLABLE. This is a
// B2B catalogue — guests get price_visible:false and price:null on every
// product. Any widget that formats a price must handle null.

import 'package:flutter/foundation.dart';

/// Currency metadata sent with every priced response. Prices arrive already
/// converted server-side, so `rate` is informational — don't multiply by it.
@immutable
class CurrencyInfo {
  final String code;
  final String symbol;
  final double rate;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.rate,
  });

  static const fallback = CurrencyInfo(code: 'TRY', symbol: '₺', rate: 1);

  factory CurrencyInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return fallback;
    return CurrencyInfo(
      code: json['code']?.toString() ?? 'TRY',
      symbol: json['symbol']?.toString() ?? '',
      rate: _toDouble(json['rate']) ?? 1,
    );
  }

  String format(double? amount) {
    if (amount == null) return '';
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

/// Server-rendered badge. The API decides which badges apply and caps the list
/// at two — the app renders whatever arrives and adds no logic of its own.
@immutable
class ProductBadge {
  /// One of: preorder, new, free_shipping, sale
  final String key;
  final String label;
  final DateTime? releaseDate;

  const ProductBadge({required this.key, required this.label, this.releaseDate});

  factory ProductBadge.fromJson(Map<String, dynamic> json) => ProductBadge(
    key: json['key']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    releaseDate: _toDate(json['release_date']),
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    if (releaseDate != null) 'release_date': releaseDate!.toIso8601String(),
  };
}

/// A product card.
@immutable
class ProductModel {
  final int id;
  final String title;

  /// The Turkish slug. This is the identifier for /products/{slug} and
  /// /products/{slug}/related — the numeric id is only used for cart adds.
  final String slug;

  final String sku;

  /// False for guests and unapproved accounts. When false, [price] is null and
  /// the UI should prompt to sign in rather than render an empty price.
  final bool priceVisible;

  /// Effective selling price, already converted to the display currency.
  final double? price;

  /// Was `regular_price`. Non-null only when the product is on sale.
  final double? oldPrice;

  /// Whole-number discount percent, e.g. 13 for "%13 İndirim".
  final int? discount;

  final CurrencyInfo currency;
  final bool inStock;

  /// Was `image`.
  final String? thumb;

  final List<ProductBadge> badges;

  /// A plain string on card resources, not an object.
  final String? category;

  const ProductModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.sku,
    required this.priceVisible,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.currency,
    required this.inStock,
    required this.thumb,
    required this.badges,
    required this.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _toInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      // The detail resource omits price_visible; infer it from the price.
      priceVisible: json['price_visible'] as bool? ?? (json['price'] != null),
      price: _toDouble(json['price']),
      oldPrice: _toDouble(json['old_price']),
      discount: _toInt(json['discount']),
      currency: CurrencyInfo.fromJson(json['currency'] as Map<String, dynamic>?),
      inStock: json['in_stock'] as bool? ?? false,
      thumb: resolveImageUrl(json['thumb'] ?? json['image']),
      badges: _list(json['badges'])
          .map((b) => ProductBadge.fromJson(b as Map<String, dynamic>))
          .toList(),
      category: _nonEmpty(json['category']),
    );
  }

  bool get isOnSale => oldPrice != null && price != null && oldPrice! > price!;

  String get formattedPrice => currency.format(price);
  String get formattedOldPrice => currency.format(oldPrice);

  /// Minimal payload for the recently-viewed cache. Prices are deliberately
  /// left out: they go stale, and they're wrong the moment the customer signs
  /// in or out. Re-fetch by slug when showing the list.
  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'sku': sku,
    'thumb': thumb,
    'category': category,
  };
}

/// The full product page.
@immutable
class ProductDetail {
  final int id;
  final String title;
  final String? shortTitle;
  final String slug;

  /// Raw HTML, including tables of vehicle compatibility. Needs an HTML
  /// renderer (flutter_html or similar) — it is not plain text.
  final String? contentHtml;

  final String sku;
  final bool priceVisible;
  final double? price;
  final double? oldPrice;
  final int? discount;
  final CurrencyInfo currency;

  final bool inStock;

  /// False when the product can't be added to the cart at all.
  final bool purchasable;

  /// Null means unlimited (pre-order, backorders, or stock not managed).
  final int? maxQuantity;

  final int? stockQuantity;
  final DateTime? preorderReleaseDate;

  /// A flat list of URL strings — NOT objects with a `src` key.
  final List<String> images;

  final List<ProductBadge> badges;
  final List<ProductTerm> categories;
  final List<ProductTerm> brands;
  final List<ProductTerm> manufacturers;
  final List<ProductAttribute> attributes;
  final List<ProductFaq> faq;

  const ProductDetail({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.slug,
    required this.contentHtml,
    required this.sku,
    required this.priceVisible,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.currency,
    required this.inStock,
    required this.purchasable,
    required this.maxQuantity,
    required this.stockQuantity,
    required this.preorderReleaseDate,
    required this.images,
    required this.badges,
    required this.categories,
    required this.brands,
    required this.manufacturers,
    required this.attributes,
    required this.faq,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: _toInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      shortTitle: _nonEmpty(json['short_title']),
      slug: json['slug']?.toString() ?? '',
      contentHtml: _nonEmpty(json['content']),
      sku: json['sku']?.toString() ?? '',
      priceVisible: json['price_visible'] as bool? ?? (json['price'] != null),
      price: _toDouble(json['price']),
      oldPrice: _toDouble(json['old_price']),
      discount: _toInt(json['discount']),
      currency: CurrencyInfo.fromJson(json['currency'] as Map<String, dynamic>?),
      inStock: json['in_stock'] as bool? ?? false,
      purchasable: json['purchasable'] as bool? ?? false,
      maxQuantity: _toInt(json['max_quantity']),
      stockQuantity: _toInt(json['stock_quantity']),
      preorderReleaseDate: _toDate(json['preorder_release_date']),
      images: _list(json['images'])
          .map(resolveImageUrl)
          .whereType<String>()
          .toList(),
      badges: _list(json['badges'])
          .map((b) => ProductBadge.fromJson(b as Map<String, dynamic>))
          .toList(),
      categories: ProductTerm.listFrom(json['categories']),
      brands: ProductTerm.listFrom(json['brands']),
      manufacturers: ProductTerm.listFrom(json['manufacturers']),
      attributes: _list(json['attributes'])
          .map((a) => ProductAttribute.fromJson(a as Map<String, dynamic>))
          .toList(),
      faq: _list(json['faq'])
          .map((f) => ProductFaq.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  String? get primaryImage => images.isNotEmpty ? images.first : null;

  bool get isPreorder => badges.any((b) => b.key == 'preorder');

  String get formattedPrice => currency.format(price);
  String get formattedOldPrice => currency.format(oldPrice);
}

/// A category, brand or manufacturer reference: `{name, slug}`.
@immutable
class ProductTerm {
  final String name;
  final String slug;

  const ProductTerm({required this.name, required this.slug});

  factory ProductTerm.fromJson(Map<String, dynamic> json) => ProductTerm(
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
  );

  static List<ProductTerm> listFrom(dynamic value) => _list(value)
      .map((e) => ProductTerm.fromJson(e as Map<String, dynamic>))
      .toList();
}

@immutable
class ProductAttribute {
  final String name;
  final List<String> values;

  const ProductAttribute({required this.name, required this.values});

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    // Shape unconfirmed — every sampled product returned an empty attributes
    // array. Adjust once a product with attributes is available.
    return ProductAttribute(
      name: json['name']?.toString() ?? '',
      values: _list(json['values']).map((v) {
        if (v is Map) return v['name']?.toString() ?? '';
        return v.toString();
      }).where((v) => v.isNotEmpty).toList(),
    );
  }
}

@immutable
class ProductFaq {
  final String question;
  final String answer;

  const ProductFaq({required this.question, required this.answer});

  factory ProductFaq.fromJson(Map<String, dynamic> json) => ProductFaq(
    question: (json['question'] ?? json['q'] ?? '').toString(),
    answer: (json['answer'] ?? json['a'] ?? '').toString(),
  );
}

/// Laravel paginator envelope: `{data, links, meta}`.
@immutable
class ProductPage {
  final List<ProductModel> products;
  final int currentPage;
  final int lastPage;
  final int total;

  const ProductPage({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? json;

    return ProductPage(
      products: _list(json['data'])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      currentPage: _toInt(meta['current_page']) ?? 1,
      lastPage: _toInt(meta['last_page']) ?? 1,
      total: _toInt(meta['total']) ?? 0,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

// ── Parsing helpers ───────────────────────────────────────────────────────
// Laravel's decimal casts serialise as strings ("200.00"), so numbers arrive
// as either num or String depending on the field.

/// Host used to resolve relative image paths.
///
/// Set once at startup from the API base URL. The API has returned both
/// absolute URLs ("https://…/uploads/x.jpg") and relative ones ("/storage/
/// x.jpg") at different times, and Image.network fails silently on the
/// relative form — a blank placeholder with no error anywhere.
String? imageBaseUrl;

/// Turns whatever the API sends into something Image.network can load.
String? resolveImageUrl(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty || raw == 'null') return null;

  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

  final base = imageBaseUrl;
  if (base == null) return raw;

  // Protocol-relative: //cdn.example.com/x.jpg
  if (raw.startsWith('//')) return 'https:$raw';

  final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final cleanPath = raw.startsWith('/') ? raw : '/$raw';

  return '$cleanBase$cleanPath';
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String? _nonEmpty(dynamic value) {
  final str = value?.toString().trim();
  return (str == null || str.isEmpty) ? null : str;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}