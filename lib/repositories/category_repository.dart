// lib/repositories/category_repository.dart
//
// GET /categories returns the full active tree, cached server-side for an
// hour. Roots carry children, and those children carry their own children —
// three levels, enough for the circles row and the drawer menu.
//
// Categories are addressed by SLUG. The integer ids from WooCommerce (like the
// old emulator id 62) mean nothing here.

import '../services/api_client.dart';

class CategoryNode {
  final int? id;
  final String name;
  final String slug;

  /// May be null — not every category has one uploaded.
  final String? image;

  final List<CategoryNode> children;

  const CategoryNode({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
    required this.children,
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    // Tolerant of the exact field names: the resource may expose the image as
    // `image`, `image_url`, or `thumb`.
    String? image;
    for (final key in ['image', 'image_url', 'thumb', 'icon']) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        image = value;
        break;
      }
    }

    return CategoryNode(
      id: (json['id'] as num?)?.toInt(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      image: image,
      children: (json['children'] as List? ?? const [])
          .map((c) => CategoryNode.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasChildren => children.isNotEmpty;
}

/// Everything a category page needs, from GET /category-page/{slug}.
class CategoryPage {
  final String name;
  final String slug;
  final String? description;
  final List<CategoryNode> children;

  /// Ancestors, root first, including this category last.
  final List<CategoryNode> breadcrumb;

  final int total;
  final double priceMin;
  final double priceMax;

  const CategoryPage({
    required this.name,
    required this.slug,
    required this.description,
    required this.children,
    required this.breadcrumb,
    required this.total,
    required this.priceMin,
    required this.priceMax,
  });

  factory CategoryPage.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] as Map<String, dynamic>?) ?? const {};
    final price = (json['price'] as Map<String, dynamic>?) ?? const {};

    return CategoryPage(
      name: category['name']?.toString() ?? '',
      slug: category['slug']?.toString() ?? '',
      description: category['description']?.toString(),
      children: (category['children'] as List? ?? const [])
          .map((c) => CategoryNode.fromJson(c as Map<String, dynamic>))
          .toList(),
      breadcrumb: (json['breadcrumb'] as List? ?? const [])
          .map((c) => CategoryNode.fromJson(c as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      priceMin: (price['min'] as num?)?.toDouble() ?? 0,
      priceMax: (price['max'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CategoryRepository {
  final ApiClient _client;

  CategoryRepository(this._client);

  /// The full tree. Roots only at the top level — walk `children` for the rest.
  Future<List<CategoryNode>> tree() async {
    final body = await _client.get('/categories');
    final data = (body as Map<String, dynamic>)['data'] as List? ?? const [];
    return data
        .map((c) => CategoryNode.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryNode> category(String slug) async {
    final body = await _client.get('/categories/$slug');
    final map = body as Map<String, dynamic>;
    // CategoryResource wraps in `data` when returned on its own.
    final data = (map['data'] as Map<String, dynamic>?) ?? map;
    return CategoryNode.fromJson(data);
  }

  /// One round trip for a category landing page: children, breadcrumb, count
  /// and price range.
  Future<CategoryPage> page(String slug) async {
    final body = await _client.get('/category-page/$slug');
    return CategoryPage.fromJson(body as Map<String, dynamic>);
  }
}
