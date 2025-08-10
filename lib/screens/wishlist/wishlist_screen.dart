import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/wishlist_provider.dart';
import 'package:shop/utils/helpers.dart';
import 'package:shop/components/product/add_to_cart_modal.dart';
import 'package:shop/entry_point.dart';
import 'package:shop/route/route_constants.dart';
import '../../providers/currency_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Future<void> _refresh() async {
    await Provider.of<WishlistProvider>(context, listen: false).loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wishListProvider = Provider.of<WishlistProvider>(context);
    final wishList = wishListProvider.wishList;
    final currency = Provider.of<CurrencyProvider>(context).selectedCurrency;
    final currencySymbol = getCurrencySymbol(currency);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('İstek Listem'),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        actions: [
          if (wishList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Temizle',
              onPressed: () async => wishListProvider.clearWishlist(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EntryPoint(
                onLocaleChange: (_) {},
                initialIndex: index,
              ),
            ),
          );
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mağaza"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: wishListProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : wishList.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.favorite_border, size: 64, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              'İstek listeniz boş',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: wishList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = wishList[index];

            // --- Correct Woo price mapping ---
            final double wooPrice     = parseWooPrice(product['price']);           // current price from Woo
            final double regularPrice = parseWooPrice(product['regular_price']);   // original price
            final double salePriceRaw = parseWooPrice(product['sale_price']);      // 0 if no sale

            // Current price shown on the card
            final double currentPrice = (salePriceRaw > 0)
                ? salePriceRaw
                : (wooPrice > 0 ? wooPrice : regularPrice);

            // Values for UI and modal
            final double displayPrice = currentPrice;
            final double? modalSalePrice = salePriceRaw > 0 ? salePriceRaw : null;
            final double? modalRegularPrice = salePriceRaw > 0 ? regularPrice : null;

            // ✅ What the MODAL should receive:
            // price = original (regular), salePrice = discounted (or null)
            final double modalPrice = modalRegularPrice ?? currentPrice;

            final image = product['images']?[0]?['src'] ?? '';
            final category = product['categories']?[0]?['name'] ?? '';
            final categoryId = product['categories']?[0]['id'] ?? 0;
            final title = product['name'] ?? '';
            final id = product['id'];
            final sku = product['sku'] ?? '';
            final bool isInStock = product['stock_status'] == 'instock';

            return Slidable(
              key: ValueKey(id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (_) => wishListProvider.removeFromWishlist(id),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Sil',
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    productDetailsScreenRoute,
                    arguments: id,
                  );
                },
                child: Stack(
                  children: [
                    // Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? Colors.white
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.grey.shade300,
                        ),
                        boxShadow: theme.brightness == Brightness.light
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : [],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white24
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.white,
                                child: image.isNotEmpty
                                    ? Image.network(
                                  image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                                )
                                    : const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Price row
                                Row(
                                  children: [
                                    Text(
                                      '$currencySymbol${displayPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    if (modalSalePrice != null &&
                                        modalRegularPrice != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '$currencySymbol${modalRegularPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration: TextDecoration.lineThrough,
                                          color: theme.textTheme.bodySmall?.color
                                              ?.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add to cart button bottom-right
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: GestureDetector(
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
                              productId: id,
                              categoryId: categoryId,
                              title: title,
                              price: modalPrice,
                              salePrice: modalSalePrice,
                              sku: sku,
                              image: image,
                              isInStock: isInStock,
                              currencySymbol: currencySymbol,
                              category: category,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: blueColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
