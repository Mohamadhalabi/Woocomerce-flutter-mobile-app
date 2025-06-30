class CategoryModel {
  final int id;
  final String name;
  final String? image;
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
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] != null ? json['image']['src'] : null,
      route: null,
      count: json['count'] ?? 0,
    );
  }
}