import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/alert_service.dart';
import 'add_to_cart_modal.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.id,
    required this.image,
    required this.category,
    required this.title,
    required this.price,
    required this.rating,
    required this.sku,
    required this.isNew,
    required this.isInStock,
    required this.currencySymbol,
    required this.categoryId,
    this.salePrice,
    this.dicountpercent,
    this.discount,
    this.freeShipping,
    required this.press,
  });

  final String image, category, title, sku;
  final double price, rating;
  final double? salePrice;
  final Map<String, dynamic>? discount;
  final int? dicountpercent, id, categoryId;
  final bool? freeShipping;
  final VoidCallback press;
  final bool isNew;
  final bool isInStock;
  final String? currencySymbol;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool hasDiscount = salePrice != null && salePrice! < price;
    final symbol = currencySymbol ?? "₺";

    // ✅ Colors from your original ProductCard for Title
    final titleColor = isDark ? Colors.white : Colors.black;
    final categoryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // ✅ Layout Colors from Horizontal Card style
    final borderColor = isDark ? Colors.grey.withOpacity(0.4) : Colors.grey.withOpacity(0.3);
    final cardColor = isDark ? theme.cardColor : Colors.white;

    return GestureDetector(
      onTap: press,
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image Section (Top Half)
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Ensure image background is white
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Opacity(
                        opacity: isInStock ? 1.0 : 0.6, // 🔹 Reduce opacity if no stock
                        child: Container(
                          alignment: Alignment.center,
                          child: Image.network(
                            image,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // "STOKTA YOK" badge
                if (!isInStock)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

                // Wishlist Button
                if (id != null)
                  Selector<WishlistProvider, bool>(
                    selector: (_, provider) => provider.isInWishlist(id!),
                    builder: (context, isWished, _) {
                      return Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            final productData = {
                              'id': id,
                              'name': title,
                              'sku': sku,
                              'images': [{'src': image}],
                              'categories': [{'name': category}],
                              'regular_price': price,
                              'sale_price': salePrice,
                              'average_rating': rating,
                              'stock_status': isInStock ? 'instock' : 'outofstock',
                              'isNew': isNew,
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
            ),

            // 📄 Info Section (Bottom Half)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: categoryColor),
                    ),
                    const SizedBox(height: 4),

                    // Title - EXACTLY as per original request
                    Text(
                      title,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: titleColor, // ✅ Restored specific color logic
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),

                    // Price + Cart Button Row
                    FutureBuilder<bool>(
                      future: isLoggedIn(),
                      builder: (context, snapshot) {
                        final loggedIn = snapshot.data ?? false;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🏷 Price
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: loggedIn
                                  ? [
                                Text(
                                  "$symbol${(hasDiscount ? salePrice : price)!.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: hasDiscount
                                        ? Colors.red
                                        : theme.primaryColor,
                                  ),
                                ),
                                if (hasDiscount)
                                  Text(
                                    "$symbol${price.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white54 : Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ]
                                  : [
                                // Optional: Placeholder for guests or leave empty
                                const SizedBox.shrink(),
                              ],
                            ),

                            // 🛒 Cart Button
                            if (price > 0 || loggedIn)
                              GestureDetector(
                                onTap: () {
                                  if (!isInStock) {
                                    AlertService.showTopAlert(
                                        context, 'Ürün stokta yok',
                                        isError: true);
                                    return;
                                  }

                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    isScrollControlled: true,
                                    builder: (context) => AddToCartModal(
                                      productId: id ?? 0,
                                      title: title,
                                      price: price,
                                      salePrice: salePrice,
                                      sku: sku,
                                      image: image,
                                      isInStock: isInStock,
                                      currencySymbol: symbol,
                                      category: category,
                                      categoryId: categoryId ?? 0,
                                    ),
                                  );
                                },
                                child: Opacity(
                                  opacity: isInStock ? 1 : 0.5,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isInStock ? blueColor : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shopping_cart_checkout_sharp,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}