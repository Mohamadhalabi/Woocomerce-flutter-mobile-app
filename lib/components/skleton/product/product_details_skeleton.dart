import 'package:flutter/material.dart';
import 'package:shop/components/skleton/skelton.dart';

class ProductDetailsSkeleton extends StatelessWidget {
  const ProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              const Skeleton(height: 300, width: double.infinity),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category placeholder
                    const Skeleton(width: 120, height: 14),
                    const SizedBox(height: 8),

                    // Title placeholder
                    const Skeleton(width: double.infinity, height: 20),
                    const SizedBox(height: 6),
                    const Skeleton(width: double.infinity, height: 20),
                    const SizedBox(height: 16),

                    // Price placeholder
                    const Skeleton(width: 100, height: 20),
                    const SizedBox(height: 16),

                    // Quantity & Button placeholder
                    Row(
                      children: [
                        const Skeleton(width: 120, height: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Skeleton(height: 48),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Attributes section placeholder
                    const Skeleton(width: 150, height: 18),
                    const SizedBox(height: 12),
                    const Skeleton(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    const Skeleton(width: double.infinity, height: 14),
                    const SizedBox(height: 24),

                    // Description section placeholder
                    const Skeleton(width: 150, height: 18),
                    const SizedBox(height: 12),
                    const Skeleton(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    const Skeleton(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    const Skeleton(width: double.infinity, height: 14),
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
