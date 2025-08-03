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
              onPressed: () async {
                await wishListProvider.clearWishlist();
              },
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
            Icon(Icons.favorite_border,
                size: 64, color: theme.disabledColor),
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
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: wishList.length,
          itemBuilder: (context, index) {
            final product = wishList[index];
            final double salePrice = parseWooPrice(product['sale_price']);
            final double price = parseWooPrice(product['regular_price']);
            final double displayPrice =
            (salePrice > 0 && salePrice < price) ? salePrice : price;
            final double rating = parseWooPrice(product['average_rating']);
            final image = product['images']?[0]?['src'] ?? '';
            final category = product['categories']?[0]?['name'] ?? '';
            final title = product['name'] ?? '';
            final id = product['id'];
            final sku = product['sku'] ?? '';
            final bool isInStock = product['stock_status'] == 'instock';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Slidable(
                key: ValueKey(id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (_) {
                        wishListProvider.removeFromWishlist(id);
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Sil',
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      productDetailsScreenRoute,
                      arguments: id,
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: theme.brightness == Brightness.dark
                              ? Border.all(
                              color: Colors.grey.shade700, width: 1)
                              : null,
                          boxShadow: [
                            if (theme.brightness == Brightness.light)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: theme.dividerColor),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                BorderRadius.circular(8),
                                child: Image.network(
                                  image,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    category,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme
                                          .textTheme.bodySmall?.color
                                          ?.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        '$currencySymbol${displayPrice.toStringAsFixed(2)}',
                                        style: theme
                                            .textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: blueColor,
                                        ),
                                      ),
                                      if (salePrice > 0 &&
                                          salePrice < price) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '$currencySymbol${price.toStringAsFixed(2)}',
                                          style: theme
                                              .textTheme.bodySmall
                                              ?.copyWith(
                                            decoration: TextDecoration
                                                .lineThrough,
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.6),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(5, (i) {
                                      if (i < rating.floor()) {
                                        return const Icon(Icons.star,
                                            size: 14,
                                            color: Colors.amber);
                                      } else if (i < rating) {
                                        return const Icon(
                                            Icons.star_half,
                                            size: 14,
                                            color: Colors.amber);
                                      } else {
                                        return const Icon(
                                            Icons.star_border,
                                            size: 14,
                                            color: Colors.amber);
                                      }
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              isScrollControlled: true,
                              builder: (context) => AddToCartModal(
                                productId: id,
                                title: title,
                                price: price,
                                salePrice: salePrice,
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
                                  color:
                                  Colors.black.withOpacity(0.1),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
