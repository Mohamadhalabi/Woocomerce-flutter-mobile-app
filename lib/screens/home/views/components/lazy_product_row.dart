// lib/screens/home/views/components/lazy_product_row.dart
//
// A home-screen row that fetches its products only when it scrolls into view.
//
// The old home screen fired five requests on open, most of which the customer
// never scrolled to. This starts as a skeleton and requests nothing until it's
// actually visible, so opening the app costs one call instead of five.
//
// No backend work needed — /products already takes these filters.

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../components/product/add_to_cart_modal_v2.dart';
import '../../../../components/product/catalog_product_card.dart';
import '../../../../components/skleton/skelton.dart';
import '../../../../models/catalog_product.dart';
import '../../../../repositories/catalog_repository.dart';
import '../../../../services/currency_service.dart';
import '../../../../services/taxonomy_service.dart';
import '../../../product/views/product_details_screen_v2.dart';

class LazyProductRow extends StatefulWidget {
  const LazyProductRow({
    super.key,
    required this.title,
    required this.query,
    required this.cacheKey,
    this.onViewAll,
    this.height = 320,
  });

  final String title;
  final ProductQuery query;

  /// Must be unique per row. Audience is appended automatically — priced
  /// responses differ for guests and signed-in customers.
  final String cacheKey;

  final VoidCallback? onViewAll;
  final double height;

  @override
  State<LazyProductRow> createState() => _LazyProductRowState();
}

class _LazyProductRowState extends State<LazyProductRow> {
  List<ProductModel>? _products;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    CurrencyService.revision.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    CurrencyService.revision.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  /// Drops the loaded products so the row refetches in the new currency. It's
  /// on screen when this fires, so loading again immediately is right.
  void _onCurrencyChanged() {
    if (!mounted) return;
    setState(() {
      _products = null;
      _failed = false;
    });
    _loadOnce();
  }

  Future<void> _loadOnce() async {
    if (_products != null || _loading) return;

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final page = await TaxonomyService.row(widget.cacheKey, widget.query);

      if (!mounted) return;
      setState(() {
        _products = page.products;
        _loading = false;
      });
    } catch (e) {
      // Surfaced rather than swallowed — a silent failure here looked
      // identical to "still loading", which made it impossible to diagnose.
      debugPrint('LazyProductRow(${widget.cacheKey}) failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      // Must be stable and unique, or the detector reuses the wrong callbacks.
      key: Key('lazy-row-${widget.cacheKey}'),
      onVisibilityChanged: (info) {
        // 10% is enough — the row starts loading just before it's fully on
        // screen, so the skeleton is rarely seen.
        if (info.visibleFraction > 0.1) _loadOnce();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Tümünü Gör'),
                  ),
              ],
            ),
          ),
          SizedBox(height: widget.height, child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (_failed) {
      return Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() => _failed = false);
            _loadOnce();
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Tekrar dene'),
        ),
      );
    }

    // Skeletons cover both the not-yet-visible and loading states, so the row
    // never collapses and the page doesn't jump as it fills in.
    if (_products == null) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 4,
        itemBuilder: (context, i) => Container(
          width: 150,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 150, radious: 12),
              SizedBox(height: 10),
              Skeleton(width: 60, height: 10),
              SizedBox(height: 6),
              Skeleton(height: 12),
              SizedBox(height: 4),
              Skeleton(width: 100, height: 12),
              Spacer(),
              Skeleton(width: 70, height: 14),
            ],
          ),
        ),
      );
    }

    if (_products!.isEmpty) {
      return const Center(
        child: Text('Ürün bulunamadı', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _products!.length,
      itemBuilder: (context, i) {
        final product = _products![i];
        return CatalogProductCard(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreenV2(slug: product.slug),
            ),
          ),
          onAddToCart: (qty) =>
              AddToCartModalV2.show(context, product, initialQuantity: qty),
        );
      },
    );
  }
}