// lib/repositories/catalog_repository.dart
//
// Replaces fetchLatestProducts / fetchFlashSaleProducts / fetchFilteredProducts
// / fetchProductsBySearch / fetchProductById and the WOOCS endpoints.
//
// Two things changed shape and cause most of the bugs when porting screens:
//   1. Products are addressed by SLUG, not integer id.
//   2. Multi-value filters are repeated params (brands[]=a&brands[]=b), and
//      attributes are integer ids from /filters. Comma-joined strings 422.

import '../models/catalog_product.dart';
import '../models/filter_models.dart';
import '../services/api_client.dart';

/// How the catalogue is sorted. Values match the API's `sort` whitelist.
enum ProductSort {
  /// Merchandised order (sort_order, then newest). The API's default.
  manual('default'),
  relevance('relevance'),
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  newest('newest'),
  name('name');

  final String value;
  const ProductSort(this.value);
}

/// Single-select badge filter. Only ONE can be applied at a time — "new AND
/// free shipping" is not expressible.
enum ProductBadgeFilter {
  newArrival('new'),
  freeShipping('free_shipping'),
  preorder('preorder');

  final String value;
  const ProductBadgeFilter(this.value);
}

/// Everything the catalogue and the filter sheet can be filtered by.
///
/// The same object drives both `/products` and `/filters`, which is what keeps
/// the sidebar counts describing the grid the customer is looking at.
class ProductQuery {
  /// A single category slug. The API includes child categories automatically,
  /// so there's no need to expand the tree client-side.
  final String? category;

  /// Brand slugs — sent as `brands[]`.
  final List<String> brands;

  /// Manufacturer slugs — sent as `manufacturers[]`.
  final List<String> manufacturers;

  /// AttributeValue ids from [FilterFacets] — sent as `attr[]`. Values within
  /// one attribute are OR'd; different attributes are AND'd.
  final List<int> attributeValueIds;

  final double? priceMin;
  final double? priceMax;
  final bool inStock;
  final bool onSale;
  final ProductBadgeFilter? badge;
  final String? search;
  final ProductSort? sort;
  final int page;

  /// Capped at 48 by the API.
  final int perPage;

  const ProductQuery({
    this.category,
    this.brands = const [],
    this.manufacturers = const [],
    this.attributeValueIds = const [],
    this.priceMin,
    this.priceMax,
    this.inStock = false,
    this.onSale = false,
    this.badge,
    this.search,
    this.sort,
    this.page = 1,
    this.perPage = 24,
  });

  ProductQuery copyWith({
    String? category,
    List<String>? brands,
    List<String>? manufacturers,
    List<int>? attributeValueIds,
    double? priceMin,
    double? priceMax,
    bool? inStock,
    bool? onSale,
    ProductBadgeFilter? badge,
    String? search,
    ProductSort? sort,
    int? page,
    int? perPage,
    bool clearBadge = false,
    bool clearSearch = false,
  }) {
    return ProductQuery(
      category: category ?? this.category,
      brands: brands ?? this.brands,
      manufacturers: manufacturers ?? this.manufacturers,
      attributeValueIds: attributeValueIds ?? this.attributeValueIds,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      inStock: inStock ?? this.inStock,
      onSale: onSale ?? this.onSale,
      badge: clearBadge ? null : (badge ?? this.badge),
      search: clearSearch ? null : (search ?? this.search),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  /// ApiClient turns List values into repeated `key[]=` params, which is what
  /// the `array` validation rules require.
  Map<String, dynamic> toParams({bool forFilters = false}) {
    final params = <String, dynamic>{
      'category': category,
      'brands': brands,
      'manufacturers': manufacturers,
      'attr': attributeValueIds.map((id) => id.toString()).toList(),
      'price_min': priceMin,
      'price_max': priceMax,
      'in_stock': inStock,
      'q': search?.trim(),
    };

    // /filters accepts none of these and would 422 on `badge`.
    if (!forFilters) {
      params['on_sale'] = onSale;
      params['badge'] = badge?.value;
      params['sort'] = sort?.value;
      params['page'] = page;
      params['per_page'] = perPage.clamp(1, 48);
    }

    return params;
  }
}

/// Typeahead result: a few products plus the full count, for "see all N".
class SuggestResult {
  final List<ProductModel> items;
  final int total;

  const SuggestResult({required this.items, required this.total});

  static const empty = SuggestResult(items: [], total: 0);
}

class CatalogRepository {
  final ApiClient _client;

  CatalogRepository(this._client);

  /// The main catalogue call. Powers the store screen, search results, and any
  /// "view all" list.
  Future<ProductPage> products(ProductQuery query) async {
    final body = await _client.get('/products', query: query.toParams());
    return ProductPage.fromJson(body as Map<String, dynamic>);
  }

  /// Full product page. [slug] comes from ProductModel.slug — the integer id
  /// will 404 here.
  Future<ProductDetail> product(String slug) async {
    final body = await _client.get('/products/$slug');
    return ProductDetail.fromJson(
      (body as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  /// Up to 8 products from the same categories, in random order — so this
  /// returns a different set each call and shouldn't be cached.
  Future<List<ProductModel>> related(String slug) async {
    final body = await _client.get('/products/$slug/related');
    final data = (body as Map<String, dynamic>)['data'] as List? ?? const [];
    return data
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Live search for the header field.
  ///
  /// The API needs 2 characters (the old app required 3) and always returns 5
  /// items — `limit` is ignored. [category] scopes the search to one category
  /// tree, matching the dropdown beside the search box.
  Future<SuggestResult> suggest(String query, {String? category}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return SuggestResult.empty;

    final body = await _client.get('/search/suggest', query: {
      'q': trimmed,
      'category': category,
    });

    final map = body as Map<String, dynamic>;
    final items = (map['items'] as List? ?? const [])
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return SuggestResult(
      items: items,
      total: (map['total'] as num?)?.toInt() ?? items.length,
    );
  }

  /// Flat brand list for menus. Cheap: no facet counting, unlike /filters.
  Future<List<TermFacet>> brands() => _taxonomy('/brands');

  Future<List<TermFacet>> manufacturers() => _taxonomy('/manufacturers');

  Future<List<TermFacet>> _taxonomy(String path) async {
    final body = await _client.get(path);
    final data = body is List
        ? body
        : (body as Map<String, dynamic>)['data'] as List? ?? const [];
    return data
        .map((t) => TermFacet.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// Facet counts for the current filters.
  ///
  /// Call this with the SAME query as [products] and refresh it whenever the
  /// filters change — counts are relative to the current result set, not
  /// absolute.
  Future<FilterFacets> filters(ProductQuery query) async {
    final body =
    await _client.get('/filters', query: query.toParams(forFilters: true));
    return FilterFacets.fromJson(body as Map<String, dynamic>);
  }
}