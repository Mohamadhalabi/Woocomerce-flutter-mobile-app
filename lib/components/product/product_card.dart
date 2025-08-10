import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../providers/wishlist_provider.dart';
import 'add_to_cart_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double finalPrice = salePrice ?? price;
    final bool hasDiscount = salePrice != null && salePrice! < price;

    return GestureDetector(
      onTap: press,
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white, // always white
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1), // border all sides
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image & badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: ColorFiltered(
                    colorFilter: isInStock
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : ColorFilter.mode(Colors.white.withOpacity(0.6), BlendMode.modulate),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 1), // bottom border
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8), // light padding all around
                        child: AspectRatio(
                          aspectRatio: 1, // keeps image area square
                          child: Container(
                            color: Colors.white, // background behind transparent PNGs
                            alignment: Alignment.center,
                            child: Image.network(
                              image,
                              fit: BoxFit.contain, // no cropping
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.broken_image, color: theme.iconTheme.color),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (!isInStock)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'STOKTA YOK',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                if (isNew && isInStock)
                  Positioned(top: 8, left: 8, child: _buildBadge('YENİ')),

                if (dicountpercent != null && isInStock)
                  Positioned(top: 8, left: 8, child: _buildBadge('-$dicountpercent%')),

                // ❤️ Wishlist
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
                            Provider.of<WishlistProvider>(context, listen: false).toggleWishlist(productData);
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isWished ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isWished ? Colors.red : theme.iconTheme.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),

            // Product info + bottom-anchored price & cart
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Colors.black,
                        height: 1.5, // ✅ line height multiplier
                      ),
                    ),

                    const Spacer(), // pushes the next Row to the bottom

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<String?>(
                          future: SharedPreferences.getInstance()
                              .then((prefs) => prefs.getString('auth_token')),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const SizedBox(height: 24);
                            }
                            final token = snapshot.data;
                            final isLoggedIn = token != null && !JwtDecoder.isExpired(token);

                            // hide if not logged in or no price
                            if (!isLoggedIn || finalPrice <= 0) {
                              return const SizedBox.shrink();
                            }

                            final bool hasDiscountNow =
                                salePrice != null && salePrice! > 0 && salePrice! < price;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${currencySymbol ?? '₺'}${(hasDiscountNow ? salePrice : price)!.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: hasDiscountNow ? Colors.red : Theme.of(context).primaryColor,
                                  ),
                                ),
                                if (hasDiscountNow) const SizedBox(height: 2),
                                if (hasDiscountNow)
                                  Text(
                                    "${currencySymbol ?? '₺'}${price.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        if (finalPrice > 0)
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                                  currencySymbol: currencySymbol ?? "₺",
                                  category: category,
                                  categoryId: categoryId ?? 0,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: blueColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_cart_checkout_sharp,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}