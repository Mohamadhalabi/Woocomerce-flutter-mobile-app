import 'package:flutter/material.dart';
import 'offers_carousel.dart';
import 'categories.dart';

class OffersCarouselAndCategories extends StatelessWidget {
  final Map<String, dynamic>? initialDrawerData;

  const OffersCarouselAndCategories({super.key, this.initialDrawerData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Categories(initialDrawerData: initialDrawerData),
        const OffersCarousel(),
      ],
    );
  }
}