class BrandModel {
  final int id;
  final String name;
  final String slug;
  final String logo; // may be empty

  BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return BrandModel(
      id: rawId is int ? rawId : int.tryParse('${rawId ?? 0}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo': logo,
  };
}
