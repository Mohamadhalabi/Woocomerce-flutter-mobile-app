class CategoryModel {
  final int id;
  final String name;
  final String? image;
  final String? route;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.route,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      image: json['image'] != null ? json['image']['src'] : null,
      route: null, // update if you're setting routes dynamically
    );
  }
}