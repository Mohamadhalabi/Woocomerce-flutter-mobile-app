import 'package:flutter/material.dart';
import 'package:shop/components/skleton/skelton.dart';

class ProductDetailsSkeleton extends StatelessWidget {
  const ProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: const SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Skeleton(height: 300, width: double.infinity),
              SizedBox(height: 16),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category placeholder
                    Skeleton(width: 120, height: 14),
                    SizedBox(height: 8),

                    // Title placeholder
                    Skeleton(width: double.infinity, height: 20),
                    SizedBox(height: 6),
                    Skeleton(width: double.infinity, height: 20),
                    SizedBox(height: 16),

                    // Price placeholder
                    Skeleton(width: 100, height: 20),
                    SizedBox(height: 16),

                    // Quantity & Button placeholder
                    Row(
                      children: [
                        Skeleton(width: 120, height: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Skeleton(height: 48),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Attributes section placeholder
                    Skeleton(width: 150, height: 18),
                    SizedBox(height: 12),
                    Skeleton(width: double.infinity, height: 14),
                    SizedBox(height: 6),
                    Skeleton(width: double.infinity, height: 14),
                    SizedBox(height: 24),

                    // Description section placeholder
                    Skeleton(width: 150, height: 18),
                    SizedBox(height: 12),
                    Skeleton(width: double.infinity, height: 14),
                    SizedBox(height: 6),
                    Skeleton(width: double.infinity, height: 14),
                    SizedBox(height: 6),
                    Skeleton(width: double.infinity, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
