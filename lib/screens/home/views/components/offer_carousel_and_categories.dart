import 'package:flutter/material.dart';
import 'offers_carousel.dart';
import 'categories.dart';

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
        Categories(initialDrawerData: initialDrawerData),
        const OffersCarousel(),
      ],
    );
  }
}