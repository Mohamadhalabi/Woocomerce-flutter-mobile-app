import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import '../../../../constants.dart';
import '../../../../services/api_service.dart';
import 'package:shop/models/category_model.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newLocale = Localizations.localeOf(context).languageCode;

    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      fetchCategories(newLocale);
    }
  }

  Future<void> fetchCategories(String locale) async {
    if (!mounted) return; // ✅ Prevent running on unmounted widget
    setState(() => isLoading = true);

    try {
      final data = await ApiService.fetchCategories(locale);
      if (!mounted) return; // ✅ Check again before calling setState
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      print('Kategori hatası: $e');
      if (!mounted) return; // ✅ Safe guard for async error path too
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
      child: Row(
        children: List.generate(
          categories.length,
              (index) => Padding(
            padding: EdgeInsets.only(
              top: 15.0,
              right: index == categories.length - 1 ? defaultPadding : 0,
            ),
            child: CategoryBtn(
              category: categories[index].name,
              image: "",
              press: () {
                if (categories[index].route != null) {
                  Navigator.pushNamed(context, categories[index].route!);
                }
              },
            ),
          ),
        ),
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
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(9),
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
            child: image != null && image.isNotEmpty
                ? Image.network(image, fit: BoxFit.contain)
                : const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 130,
            child: Text(
              category,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: greenColor
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