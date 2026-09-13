// lib/screens/home/views/components/categories_v2.dart
//
// Same circles as the original Categories widget, sourced from GET /categories
// instead of the WooCommerce drawer payload.
//
// NOTE: every category currently returns image: null from the API — the column
// exists but nothing has been uploaded in the admin yet. Until then the
// circles fall back to the category's initial. No code change needed once the
// images are added.

import 'package:flutter/material.dart';

import '../../../../components/skleton/others/categories_skelton.dart';
import '../../../../constants.dart';
import '../../../../repositories/category_repository.dart';
import '../../../../services/app_api.dart';

class CategoriesV2 extends StatefulWidget {
  const CategoriesV2({super.key, required this.onCategoryTap});

  final void Function(CategoryNode category) onCategoryTap;

  @override
  State<CategoriesV2> createState() => _CategoriesV2State();
}

class _CategoriesV2State extends State<CategoriesV2> {
  // The tree is cached server-side for an hour, but holding it here too avoids
  // refetching every time the home tab rebuilds.
  static List<CategoryNode>? _cached;

  List<CategoryNode> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    if (_cached != null) {
      _categories = _cached!;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await categoryRepo.tree();
      if (!mounted) return;

      setState(() {
        _cached = data;
        _categories = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CategoriesSkelton());
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Row(
        children: _categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: defaultPadding, top: 16),
            child: CategoryBtnV2(
              category: cat,
              press: () => widget.onCategoryTap(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryBtnV2 extends StatelessWidget {
  const CategoryBtnV2({
    super.key,
    required this.category,
    required this.press,
  });

  final CategoryNode category;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final image = category.image;

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
            clipBehavior: Clip.hardEdge,
            child: image != null && image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 90,
            child: Text(
              category.name,
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

  /// Stand-in until category images are uploaded — the initial reads better
  /// than a broken-image icon repeated twenty times.
  Widget _placeholder() {
    final initial =
        category.name.isNotEmpty ? category.name.characters.first : '?';

    return Container(
      color: greenColor.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: greenColor,
        ),
      ),
    );
  }
}
