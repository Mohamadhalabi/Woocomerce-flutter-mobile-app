// lib/models/filter_models.dart
//
// Mirrors GET /filters (FilterController::index).
//
// The important thing here: attribute values are filtered by INTEGER id, not
// by name. Those ids only exist in this response, so the filter sheet has to
// load facets before it can build a query.

import 'package:flutter/foundation.dart';

/// One selectable value, e.g. "433MHz" under the "Frekans" attribute.
@immutable
class AttributeValueFacet {
  /// Send this back as `attr[]`.
  final int id;
  final String name;
  final String slug;

  /// How many products in the current result set carry this value. Counts are
  /// computed with every filter EXCEPT this attribute's own, so ticking a
  /// second value in the same group doesn't zero out the others.
  final int count;

  const AttributeValueFacet({
    required this.id,
    required this.name,
    required this.slug,
    required this.count,
  });

  factory AttributeValueFacet.fromJson(Map<String, dynamic> json) =>
      AttributeValueFacet(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// An attribute group, e.g. "Frekans" with its values.
@immutable
class AttributeFacet {
  final int id;
  final String name;
  final String slug;
  final List<AttributeValueFacet> values;

  const AttributeFacet({
    required this.id,
    required this.name,
    required this.slug,
    required this.values,
  });

  factory AttributeFacet.fromJson(Map<String, dynamic> json) => AttributeFacet(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    values: (json['values'] as List? ?? const [])
        .map((v) => AttributeValueFacet.fromJson(v as Map<String, dynamic>))
        .toList(),
  );
}

/// A brand or manufacturer option. Filtered by [slug], not by id.
@immutable
class TermFacet {
  final String name;
  final String slug;
  final int count;

  const TermFacet({
    required this.name,
    required this.slug,
    required this.count,
  });

  factory TermFacet.fromJson(Map<String, dynamic> json) => TermFacet(
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

/// The whole sidebar.
@immutable
class FilterFacets {
  final List<AttributeFacet> attributes;
  final List<TermFacet> brands;
  final List<TermFacet> manufacturers;

  /// KNOWN ISSUE: these bounds come straight from the database in base
  /// currency (USD), while product prices are converted to the display
  /// currency. Don't build a price slider from them until the backend fixes it
  /// — see backend-requirements.md §3.5.
  final double priceMin;
  final double priceMax;

  const FilterFacets({
    required this.attributes,
    required this.brands,
    required this.manufacturers,
    required this.priceMin,
    required this.priceMax,
  });

  static const empty = FilterFacets(
    attributes: [],
    brands: [],
    manufacturers: [],
    priceMin: 0,
    priceMax: 0,
  );

  factory FilterFacets.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as Map<String, dynamic>?) ?? const {};

    return FilterFacets(
      attributes: (json['attributes'] as List? ?? const [])
          .map((a) => AttributeFacet.fromJson(a as Map<String, dynamic>))
          .toList(),
      brands: (json['brands'] as List? ?? const [])
          .map((b) => TermFacet.fromJson(b as Map<String, dynamic>))
          .toList(),
      manufacturers: (json['manufacturers'] as List? ?? const [])
          .map((m) => TermFacet.fromJson(m as Map<String, dynamic>))
          .toList(),
      priceMin: (price['min'] as num?)?.toDouble() ?? 0,
      priceMax: (price['max'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isEmpty =>
      attributes.isEmpty && brands.isEmpty && manufacturers.isEmpty;
}