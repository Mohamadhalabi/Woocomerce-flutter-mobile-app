import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'product_card_skelton.dart';

class ProductCategorySkelton extends StatelessWidget {
  const ProductCategorySkelton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.65,
        children: List.generate(4, (_) => const ProductCardSkelton()),
      ),
    );
  }
}