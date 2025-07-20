class ProductModel {
  final int id;
  final String title;
  final String image;
  final String category;
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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final DateTime createdDate = DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now();
    final List<dynamic> metaData = json['meta_data'] ?? [];

    // ✅ Parse attributes into Map<String, List<String>>
    final attributeMap = <String, List<String>>{};
    if (json['attributes'] != null && json['attributes'] is List) {
      for (var item in json['attributes']) {
        if (item['name'] != null && item['options'] != null) {
          attributeMap[item['name']] = List<String>.from(item['options']);
        }
      }
    }

    return ProductModel(
      id: json['id'],
      title: json['name'] ?? 'No Title',
      image: (json['images'] != null && json['images'].isNotEmpty) ? json['images'][0]['src'] : '',
      images: json['images'] != null
          ? List<String>.from(json['images'].map((img) => img['src']))
          : [],
      description: json['description'] ?? '',
      category: json['categories'] != null && json['categories'].isNotEmpty
          ? json['categories'][0]['name']
          : 'Uncategorized',
      sku: json['sku'] ?? '',
      price: double.tryParse(json['regular_price'].toString()) ?? 0.0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      discountPercent: json['discount_percent'],
      discount: json['discount'],
      freeShipping: json['free_shipping'] == 1,
      isNew: checkIsNewFromMetaData(metaData) ||
          createdDate.isAfter(DateTime.now().subtract(const Duration(days: 7))),
      rating: double.tryParse(json['average_rating'].toString()) ?? 0.0,
      attributes: attributeMap,
      isInStock: json['stock_status'] == 'instock',
      currencySymbol: (json['currency'] == 'USD')
          ? '\$'
          : (json['currency'] == 'TRY')
          ? '₺'
          : (json['currency_symbol'] ?? '₺'),
    );
  }

  static bool checkIsNewFromMetaData(List<dynamic> metaData) {
    for (var item in metaData) {
      if (item['key'] == '_yith_wcbm_badges' &&
          item['value'] is List &&
          item['value'].isNotEmpty) {
        final badgeText = item['value'][0]['text']?.toString().toLowerCase() ?? '';
        if (badgeText.contains('yeni')) return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    final resolvedCurrencySymbol = (currencySymbol == 'USD')
        ? '\$'
        : (currencySymbol == 'TRY')
        ? '₺'
        : (currencySymbol ?? '₺');

    return {
      'id': id,
      'title': title,
      'image': image,
      'category': category,
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
      'currency_symbol': resolvedCurrencySymbol,
    };
  }
}