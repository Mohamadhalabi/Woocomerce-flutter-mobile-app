// lib/components/skleton/app_skeletons.dart
//
// Page-level loading shapes, built on the existing Skeleton widget.
//
// Skeletons over spinners for whole-screen loads: they reserve the space the
// content will occupy, so nothing jumps when it arrives, and they tell the
// customer what's coming rather than just that something is happening.
//
// In-button spinners stay — there the signal is "your tap is being processed",
// which a skeleton doesn't convey.

import 'package:flutter/material.dart';

import 'skelton.dart';

/// A horizontal product row, matching CatalogProductCard's footprint.
class ProductRowSkeleton extends StatelessWidget {
  const ProductRowSkeleton({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Skeleton(width: 120, height: 16),
          ),
        SizedBox(
          height: 308,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 4,
            itemBuilder: (_, __) => Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(height: 150, radious: 12),
                  const SizedBox(height: 10),
                  const Skeleton(width: 60, height: 10),
                  const SizedBox(height: 6),
                  const Skeleton(height: 12),
                  const SizedBox(height: 4),
                  const Skeleton(width: 100, height: 12),
                  const Spacer(),
                  const Skeleton(width: 70, height: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width banner placeholder.
class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key, this.ratio = 23 / 9});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Skeleton(height: width / ratio, radious: 12),
    );
  }
}

/// Stacked rows, for lists like orders.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 72,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Skeleton(height: itemHeight, radious: 12),
      ),
    );
  }
}

/// Labelled input placeholders, for forms that load their values.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key, this.fields = 4});

  final int fields;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var i = 0; i < fields; i++) ...[
          const Skeleton(width: 90, height: 12),
          const SizedBox(height: 8),
          const Skeleton(height: 52, radious: 12),
          const SizedBox(height: 20),
        ],
        const Skeleton(height: 48, radious: 12),
      ],
    );
  }
}

/// Short lines, for the drawer's expanding sections.
class MenuSkeleton extends StatelessWidget {
  const MenuSkeleton({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Skeleton(height: 12)),
                SizedBox(width: 40),
                Skeleton(width: 46, height: 10),
              ],
            ),
          ),
      ],
    );
  }
}