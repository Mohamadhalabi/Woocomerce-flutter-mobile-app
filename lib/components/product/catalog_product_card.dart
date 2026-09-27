// lib/components/product/catalog_product_card.dart
//
// Visual twin of your existing ProductCard, driven by the new API's
// ProductModel.
//
// Changes in this version:
//   - quantity stepper built into the card
//   - the "Fiyat için giriş yapın" prompt is gone; when prices are hidden the
//     price area is simply blank
//   - add-to-cart reports the chosen quantity to the parent
//   - the title uses as many lines as fit (up to 4), so a long title is cut
//     with "…" instead of pushing the price and cart button off the card

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../skleton/skelton.dart';
import '../../constants.dart';
import '../../models/catalog_product.dart';
import '../../providers/wishlist_provider.dart';

class CatalogProductCard extends StatefulWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.width = 150,
    this.maxQuantity = 999,
  });

  final ProductModel product;
  final VoidCallback onTap;

  /// Receives the quantity chosen on the card.
  final void Function(int quantity)? onAddToCart;

  final double width;
  final int maxQuantity;

  @override
  State<CatalogProductCard> createState() => _CatalogProductCardState();
}

class _CatalogProductCardState extends State<CatalogProductCard> {
  int _quantity = 1;
  bool _busy = false;

  /// Title text metrics, shared by the style and the fit calculation.
  static const double _titleFontSize = 11;
  static const double _titleLineHeight = 1.65;
  static const int _titleMaxLines = 4;

  ProductModel get product => widget.product;

  String _fixHtml(String text) => text
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  Future<void> _add() async {
    if (widget.onAddToCart == null || _busy) return;

    setState(() => _busy = true);
    widget.onAddToCart!(_quantity);

    // Brief lockout so a double tap doesn't add twice.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : Colors.black;
    final categoryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor =
    isDark ? Colors.grey.withOpacity(0.4) : Colors.grey.withOpacity(0.3);
    final cardColor = isDark ? theme.cardColor : Colors.white;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageSection(context, isDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.category != null)
                      Text(
                        _fixHtml(product.category!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: categoryColor),
                      ),
                    const SizedBox(height: 2),

                    // Takes whatever height is left between the category and
                    // the price. Up to 4 lines: product names here start with
                    // a code and carry the vehicle, so cutting at two often
                    // hid the part that identifies it. But only as many as
                    // actually fit — in the wider grid cards the image is
                    // taller, and a fixed 4 lines pushed the price and cart
                    // button off the bottom ("BOTTOM OVERFLOWED").
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final lineHeight = MediaQuery.textScalerOf(context)
                              .scale(_titleFontSize) *
                              _titleLineHeight;
                          final lines = (box.maxHeight / lineHeight)
                              .floor()
                              .clamp(1, _titleMaxLines);

                          return Text(
                            product.title,
                            maxLines: lines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: _titleFontSize,
                              color: titleColor,
                              // Line spacing. At 4 lines of 11px the text
                              // reads as a block otherwise — these titles are
                              // long and start with a part code, so the eye
                              // needs the separation.
                              height: _titleLineHeight,
                            ),
                          );
                        },
                      ),
                    ),

                    if (product.priceVisible && product.price != null)
                      _price(theme, isDark),
                    const SizedBox(height: 4),
                    _quantityAndCart(theme, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stacked, not side by side: at 150px wide a row truncates both figures
  /// to "₺1092...." once the old price is shown too.
  Widget _price(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.formattedPrice,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: primaryColor,
          ),
        ),
        if (product.isOnSale)
          Text(
            product.formattedOldPrice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  /// Compact stepper plus cart button, sized to fit a 150px card.
  Widget _quantityAndCart(ThemeData theme, bool isDark) {
    final enabled = product.inStock && widget.onAddToCart != null;
    final stepperBorder =
    isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: stepperBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepButton(
                  icon: Icons.remove,
                  enabled: enabled && _quantity > 1,
                  onTap: () => setState(() => _quantity--),
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _stepButton(
                  icon: Icons.add,
                  enabled: enabled && _quantity < widget.maxQuantity,
                  onTap: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: enabled ? _add : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: enabled ? blueColor : Colors.grey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: _busy
                  ? const Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(
                Icons.shopping_cart_checkout_sharp,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 26,
        height: 28,
        child: Icon(
          icon,
          size: 14,
          color: enabled ? null : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _imageSection(BuildContext context, bool isDark) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AspectRatio(
              // Slightly wider than tall: product photos are mostly keys and
              // remotes shot on white, so a square wastes vertical space the
              // card can't afford in a two-column grid.
              aspectRatio: 1.15,
              child: Opacity(
                opacity: product.inStock ? 1.0 : 0.6,
                child: Container(
                  alignment: Alignment.center,
                  child: product.thumb == null
                      ? const Icon(Icons.image_not_supported,
                      color: Colors.grey)
                  // Cached to disk, so scrolling back up and relaunching
                  // the app both read from storage instead of the network.
                      : CachedNetworkImage(
                    imageUrl: product.thumb!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    // Decoded at roughly the size it's drawn rather than
                    // full resolution — a grid of 20 cards holds a
                    // fraction of the memory, and scrolling stops
                    // stuttering on cheaper devices.
                    memCacheWidth: 300,
                    fadeInDuration: const Duration(milliseconds: 150),
                    placeholder: (_, __) => const Skeleton(radious: 8),
                    errorWidget: (_, url, error) {
                      debugPrint('IMAGE FAILED: $url → $error');
                      return const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Server-rendered, already prioritised and capped at 2.
        if (product.badges.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: product.badges
                  .map((b) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _badgeColor(b.key),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  b.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ))
                  .toList(),
            ),
          ),

        if (!product.inStock)
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'STOKTA YOK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),

        Selector<WishlistProvider, bool>(
          selector: (_, provider) => provider.isInWishlist(product.id),
          builder: (context, isWished, _) {
            return Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  // Shaped like the old Woo payload so WishlistProvider keeps
                  // working untouched.
                  final productData = {
                    'id': product.id,
                    'name': product.title,
                    'sku': product.sku,
                    'images': [
                      {'src': product.thumb ?? ''}
                    ],
                    'categories': [
                      {'name': product.category ?? ''}
                    ],
                    'regular_price': product.oldPrice ?? product.price ?? 0,
                    'sale_price': product.isOnSale ? product.price : null,
                    'average_rating': 0,
                    'stock_status':
                    product.inStock ? 'instock' : 'outofstock',
                    'isNew': product.badges.any((b) => b.key == 'new'),
                  };
                  Provider.of<WishlistProvider>(context, listen: false)
                      .toggleWishlist(productData);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    isWished ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isWished
                        ? Colors.red
                        : (isDark ? Colors.white : Colors.grey),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _badgeColor(String key) {
    switch (key) {
      case 'sale':
        return Colors.red;
      case 'new':
        return Colors.green;
      case 'free_shipping':
        return Colors.blue;
      case 'preorder':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}