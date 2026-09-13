// lib/repositories/home_repository.dart
//
// GET /home returns everything above the fold in ONE call — replacing the five
// separate requests the old home screen made.
//
// Sections further down (featured / deal / collection) are fetched separately
// and cached per audience on the server, so they must be refetched after sign
// in or sign out.

import '../models/catalog_product.dart';
import '../services/api_client.dart';

/// A slider image with an optional link.
class HomeSlide {
  final String image;
  final String? link;
  final String? alt;

  const HomeSlide({required this.image, this.link, this.alt});

  factory HomeSlide.fromJson(Map<String, dynamic> json) => HomeSlide(
    // Same resolver as products: slider paths have arrived relative too.
    image: resolveImageUrl(json['image']) ?? '',
    link: json['link']?.toString(),
    alt: json['alt']?.toString(),
  );
}

class HomeData {
  final List<HomeSlide> hero;
  final List<HomeSlide> promos;
  final List<HomeSlide> banners;
  final List<ProductModel> newProducts;

  const HomeData({
    required this.hero,
    required this.promos,
    required this.banners,
    required this.newProducts,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    List<HomeSlide> slides(String key) =>
        (json[key] as List? ?? const [])
            .map((s) => HomeSlide.fromJson(s as Map<String, dynamic>))
            .where((s) => s.image.isNotEmpty)
            .toList();

    return HomeData(
      hero: slides('hero'),
      promos: slides('promos'),
      banners: slides('banners'),
      // Note: a bare array here, NOT wrapped in `data`.
      newProducts: (json['new_products'] as List? ?? const [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One below-the-fold section: a set of category tabs.
class HomeSection {
  final List<HomeTab> tabs;
  final ProductModel? deal;

  const HomeSection({required this.tabs, this.deal});

  factory HomeSection.fromJson(Map<String, dynamic> json) => HomeSection(
    tabs: (json['tabs'] as List? ?? const [])
        .map((t) => HomeTab.fromJson(t as Map<String, dynamic>))
        .toList(),
    deal: json['deal'] is Map<String, dynamic>
        ? ProductModel.fromJson(json['deal'] as Map<String, dynamic>)
        : null,
  );
}

class HomeTab {
  final String name;
  final String slug;
  final ProductModel? featured;
  final List<ProductModel> products;

  const HomeTab({
    required this.name,
    required this.slug,
    this.featured,
    required this.products,
  });

  factory HomeTab.fromJson(Map<String, dynamic> json) => HomeTab(
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    featured: json['featured'] is Map<String, dynamic>
        ? ProductModel.fromJson(json['featured'] as Map<String, dynamic>)
        : null,
    products: (json['products'] as List? ?? const [])
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}

class HomeRepository {
  final ApiClient _client;

  HomeRepository(this._client);

  Future<HomeData> fetchHome() async {
    final body = await _client.get('/home');
    return HomeData.fromJson(body as Map<String, dynamic>);
  }

  /// [section] must be one of: featured, deal, collection. Anything else 404s.
  Future<HomeSection> fetchSection(String section) async {
    final body = await _client.get('/home/sections/$section');
    return HomeSection.fromJson(body as Map<String, dynamic>);
  }
}