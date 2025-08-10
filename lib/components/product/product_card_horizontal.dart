import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import 'add_to_cart_modal.dart';

class ProductCardHorizontal extends StatelessWidget {
  const ProductCardHorizontal({
    super.key,
    required this.id,
    required this.image,
    required this.category,
    required this.categoryId,
    required this.title,
    required this.price,
    required this.rating,
    required this.sku,
    required this.isNew,
    this.salePrice,
    this.dicountpercent,
    this.discount,
    this.freeShipping,
    required this.press,
    required this.currencySymbol,
  });

  final String image, category, title, sku;
  final double price, rating;
  final double? salePrice;
  final Map<String, dynamic>? discount;
  final int? dicountpercent, id , categoryId;
  final bool? freeShipping;
  final VoidCallback press;
  final bool isNew;
  final String? currencySymbol;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasDiscount = salePrice != null && salePrice! < price;
    final symbol = currencySymbol ?? "₺";

    return GestureDetector(
      onTap: press,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.brightness == Brightness.dark
              ? theme.cardColor
              : Colors.white,
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 🖼 Image
            SizedBox(
              width: 120, // tweak 96–120 as you like
              height: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8), // light breathing room
                  child: AspectRatio(
                    aspectRatio: 1, // stay square without expanding row width
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.white, // background for transparent PNGs
                      child: Image.network(
                        image,
                        fit: BoxFit.contain, // no cropping
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image, color: Theme.of(context).iconTheme.color),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 📄 Info
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                        theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),

                    // Price Section
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
                                        : Theme.of(context)
                                        .primaryColor,
                                  ),
                                ),
                                if (hasDiscount)
                                  Text(
                                    "$symbol${price.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme
                                          .textTheme.bodySmall?.color
                                          ?.withOpacity(0.6),
                                      decoration:
                                      TextDecoration.lineThrough,
                                    ),
                                  ),
                              ]
                                  : [
                                Text(
                                  "",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme
                                        .textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),

                            // 🛒 Cart Button
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  builder: (context) => AddToCartModal(
                                    productId: id ?? 0,
                                    title: title,
                                    price: price,
                                    salePrice: salePrice,
                                    sku: sku,
                                    category: category,
                                    categoryId: categoryId ?? 0,
                                    isInStock: true,
                                    image: image,
                                    currencySymbol: symbol,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: blueColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_checkout_sharp,
                                  color: Colors.white,
                                  size: 16,
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