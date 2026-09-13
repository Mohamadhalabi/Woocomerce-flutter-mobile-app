import 'package:flutter/material.dart';
import 'package:shop/screens/home/views/components/categories_v2.dart';
import '../../../category/category_products_screen_v2.dart';
import 'offers_carousel.dart';
// import 'categories.dart';

// for testing
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart'; // Required for the Clipboard

class OffersCarouselAndCategories extends StatelessWidget {
  final Map<String, dynamic>? initialDrawerData;

  const OffersCarouselAndCategories({super.key, this.initialDrawerData});

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoriesV2(
            onCategoryTap: (category) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreenV2(
              categorySlug: category.slug,
              title: category.name,
             ),
            ),
          ),
        ),
        const OffersCarousel(),
      ],
    );
  }
}