import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/screens/category/category_products_screen.dart';
import '../../../../constants.dart';
import '../../../../services/api_service.dart';

class Categories extends StatefulWidget {
  final Map<String, dynamic>? initialDrawerData;
  const Categories({super.key, this.initialDrawerData});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  static final Map<String, List<CategoryModel>> _cachedByLocale = {};
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newLocale = Localizations.localeOf(context).languageCode;
    if (_currentLocale == newLocale) return;

    _currentLocale = newLocale;

    // If splash preloaded categories, try to use them (handle List OR Map)
    final pre = widget.initialDrawerData?['categories'];
    if (pre != null) {
      final parsed = _parseInitialCategories(pre);
      if (parsed.isNotEmpty) {
        categories = parsed;
        _cachedByLocale[newLocale] = parsed;
        isLoading = false;
        setState(() {});
        return;
      }
    }

    // Otherwise, normal cache/API logic
    if (_cachedByLocale.containsKey(newLocale)) {
      categories = _cachedByLocale[newLocale]!;
      isLoading = false;
      setState(() {});
    } else {
      fetchCategories(newLocale);
    }
  }

  /// Accepts either:
  /// - List<dynamic> of maps or models
  /// - Map<String, dynamic> whose values are maps
  List<CategoryModel> _parseInitialCategories(dynamic raw) {
    Iterable items;

    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      items = (raw as Map).values;
    } else {
      return [];
    }

    final result = <CategoryModel>[];
    for (final e in items) {
      if (e is CategoryModel) {
        result.add(e);
      } else if (e is Map<String, dynamic>) {
        result.add(CategoryModel.fromJson(e));
      } else if (e is Map) {
        // loosely typed map
        result.add(CategoryModel.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return result;
  }

  Future<void> fetchCategories(String locale) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await ApiService.fetchCategories(locale);
      if (!mounted) return;

      setState(() {
        _cachedByLocale[locale] = data;
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Kategori hatası: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CategoriesSkelton());

    if (categories.isEmpty) {
      return const Center(child: Text("No categories found"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: defaultPadding, top: 16),
            child: CategoryBtn(
              category: cat.name,
              image: cat.image ?? '',
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryProductsScreen(
                      id: cat.id,
                      title: cat.name,
                      filterType: 'category',
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    required this.image,
    required this.press,
  });

  final String category;
  final String image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: BorderRadius.circular(45),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                )
              ],
            ),
            clipBehavior: Clip.hardEdge, // important for circular clipping
            child: image.isNotEmpty
                ? Image.network(
              image,
              fit: BoxFit.cover, // fills the circle
            )
                : const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 90,
            child: Text(
              category,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: greenColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


