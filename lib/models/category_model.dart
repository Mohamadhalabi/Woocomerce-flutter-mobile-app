class CategoryModel {
  final int id;
  final String name;
  final String? image; // URL string or null
  final String? route;
  final int count;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.count,
    this.route,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // ---- image can be:
    // 1) String URL: "https://..."
    // 2) Map: { src: "...", url: "...", thumbnail: "..." }
    // 3) null / missing
    String? img;
    final rawImg = json['image'];

    if (rawImg is String) {
      img = rawImg;
    } else if (rawImg is Map<String, dynamic>) {
      img = (rawImg['src'] ?? rawImg['url'] ?? rawImg['thumbnail']) as String?;
    } else {
      img = null;
    }

    // id / count may come as String or int
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return CategoryModel(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      image: (img != null && img.isNotEmpty) ? img : null,
      route: null,
      count: parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'route': route,
    'count': count,
  };
}
