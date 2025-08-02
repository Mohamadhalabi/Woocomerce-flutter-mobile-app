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
  final int? dicountpercent, id;
  final bool? freeShipping;
  final VoidCallback press;
  final bool isNew;
  final bool isInStock;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    final double finalPrice = salePrice ?? price;
    final bool hasDiscount = salePrice != null && salePrice! < price;

    return GestureDetector(
      onTap: press,
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6,vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟧 Product image with discount
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
                    child: Image.network(
                      image,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (isNew && isInStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'YENİ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (dicountpercent != null && isInStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '-$dicountpercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

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
                              'images': [
                                {'src': image}
                              ],
                              'categories': [
                                {'name': category}
                              ],
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
                              color: isWished ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: const Color(0xFF222222), // slightly darker than default
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        if (index < rating.floor()) {
                          return const Icon(Icons.star, color: Colors.amber, size: 14);
                        } else if (index < rating && rating - index >= 0.5) {
                          return const Icon(Icons.star_half, color: Colors.amber, size: 14);
                        } else {
                          return const Icon(Icons.star_border, color: Colors.amber, size: 14);
                        }
                      }),
                      const SizedBox(width: 4),
                      Text('(${rating.toStringAsFixed(1)})', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
// Inside the Row -> Column for the price
                          FutureBuilder<String?>(
                            future: SharedPreferences.getInstance().then((prefs) => prefs.getString('auth_token')),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState != ConnectionState.done) {
                                return const SizedBox(height: 24); // loading space
                              }

                              final token = snapshot.data;
                              final isLoggedIn = token != null && !JwtDecoder.isExpired(token);

                              if (!isLoggedIn) {
                                return const SizedBox.shrink(); // ❌ No text if not logged in
                              }

                              // ✅ Hide price if 0
                              if ((salePrice ?? price) <= 0) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$currencySymbol${finalPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.red,
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Text(
                                      "$currencySymbol${price.toStringAsFixed(2)}",
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
                        ],
                      ),

                      if ((salePrice ?? price) > 0)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
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
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: blueColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.shopping_cart_checkout_sharp,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}