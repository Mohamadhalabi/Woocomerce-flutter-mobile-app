import 'package:flutter/material.dart';
import '../../../../constants.dart';

class ProductInfo extends StatelessWidget {
  const ProductInfo({
    super.key,
    required this.title,
    required this.summaryName,
    required this.sku,
  });

  final String title, summaryName, sku;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(defaultPadding),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: defaultPadding / 2),
            Text(
              sku,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: blueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (summaryName.trim().isNotEmpty) ...[
              Text(
                summaryName,
                maxLines: 2,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: greenColor,
                ),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ],
        ),
      ),
    );
  }
}