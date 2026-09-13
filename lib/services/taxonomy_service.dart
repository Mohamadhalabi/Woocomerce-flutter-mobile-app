// lib/services/taxonomy_service.dart
//
// Cached access to the drawer and home data.
//
// NO ApiCache here. That layer added a disk round-trip, an in-flight map and a
// stale-while-revalidate path — three places a request could get stuck, and
// the drawer did get stuck. This is a plain in-memory cache: the request
// either completes or throws, and ApiClient's own 30-second timeout is the
// only backstop needed.
//
// The trade-off is that the cache no longer survives an app restart. For a
// menu that's fine.

import '../models/catalog_product.dart';
import '../models/filter_models.dart';
import '../repositories/category_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/home_repository.dart';
import 'app_api.dart';

class _Cached<T> {
  final T value;
  final DateTime at;

  _Cached(this.value, this.at);

  bool isFresh(Duration ttl) => DateTime.now().difference(at) < ttl;
}

class TaxonomyService {
  static const _longTtl = Duration(hours: 6);
  static const _homeTtl = Duration(minutes: 15);

  static _Cached<List<CategoryNode>>? _categories;
  static _Cached<List<TermFacet>>? _brands;
  static _Cached<List<TermFacet>>? _manufacturers;
  static final Map<String, _Cached<HomeData>> _home = {};
  static final Map<String, _Cached<ProductPage>> _rows = {};

  /// Signed-in and guest responses differ — prices are hidden from guests — so
  /// anything priced is cached under its own key.
  static String get _audience => authRepo.isSignedIn ? 'auth' : 'guest';

  // ── Drawer ──────────────────────────────────────────────────────────────

  static Future<List<CategoryNode>> categories() async {
    final cached = _categories;
    if (cached != null && cached.isFresh(_longTtl)) return cached.value;

    final data = await categoryRepo.tree();
    _categories = _Cached(data, DateTime.now());
    return data;
  }

  /// Dedicated endpoints, not /filters — that one counts facets across the
  /// whole catalogue to return a handful of names, which is what made the
  /// drawer slow.
  static Future<List<TermFacet>> brands() async {
    final cached = _brands;
    if (cached != null && cached.isFresh(_longTtl)) return cached.value;

    final data = await catalogRepo.brands();
    _brands = _Cached(data, DateTime.now());
    return data;
  }

  static Future<List<TermFacet>> manufacturers() async {
    final cached = _manufacturers;
    if (cached != null && cached.isFresh(_longTtl)) return cached.value;

    final data = await catalogRepo.manufacturers();
    _manufacturers = _Cached(data, DateTime.now());
    return data;
  }

  // ── Home ────────────────────────────────────────────────────────────────

  static Future<HomeData> home() async {
    final key = _audience;
    final cached = _home[key];
    if (cached != null && cached.isFresh(_homeTtl)) return cached.value;

    final data = await homeRepo.fetchHome();
    _home[key] = _Cached(data, DateTime.now());
    return data;
  }

  /// A product row for the home screen. [key] must be unique per row.
  static Future<ProductPage> row(String key, ProductQuery query) async {
    final cacheKey = '$key:$_audience';
    final cached = _rows[cacheKey];
    if (cached != null && cached.isFresh(_homeTtl)) return cached.value;

    final page = await catalogRepo.products(query);
    _rows[cacheKey] = _Cached(page, DateTime.now());
    return page;
  }

  /// Call on sign in and sign out — prices, home sections and cart visibility
  /// all change with the audience.
  static Future<void> onAuthChanged() async {
    _home.clear();
    _rows.clear();
    // Categories are the same for everyone, so they survive.
  }

  static void clearAll() {
    _categories = null;
    _brands = null;
    _manufacturers = null;
    _home.clear();
    _rows.clear();
  }
}