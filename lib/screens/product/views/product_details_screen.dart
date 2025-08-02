import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/product/views/components/product_attributes.dart';
import '../../../components/product/related_products.dart';
import '../../../components/skleton/product/product_details_skeleton.dart';
import '../../../services/api_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/alert_service.dart';
import '../../../components/common/app_bar.dart';
import '../../../components/common/drawer.dart';
import '../../../entry_point.dart';
import '../../../providers/wishlist_provider.dart';

import 'components/expandable_section.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.onLocaleChange,
    required this.onTabChange,
  });

  final int productId;
  final Function(String) onLocaleChange;
  final Function(int) onTabChange;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  String? _currentLocale;
  double price = 0;
  double? salePrice;
  int quantity = 1;
  bool isInStock = true;
  String currencySymbol = '₺';
  int currentIndex = 2;
  bool _hasFetchedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;

    if (_currentLocale != locale) {
      _currentLocale = locale;
      if (!_hasFetchedOnce) {
        fetchProductDetails();
      }
    }
  }

  Future<void> fetchProductDetails({bool isRefresh = false}) async {
    if (_hasFetchedOnce && !isRefresh) return; // prevent re-fetch
    if (_currentLocale == null) return;

    setState(() => isLoading = true);

    try {
      final result =
      await ApiService.fetchProductById(widget.productId, _currentLocale!);
      final data = result.toJson();
      setState(() {
        product = data;
        price = (data['price'] as num?)?.toDouble() ?? 0.0;
        salePrice = data['sale_price'] != null
            ? (data['sale_price'] as num).toDouble()
            : null;
        isInStock = data['stock_status'] == 'instock';
        currencySymbol = data['currency_symbol'] ?? '₺';
        isLoading = false;
        _hasFetchedOnce = true;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _handleAddToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final image = (product?['gallery'] as List).isNotEmpty
        ? product!['gallery'][0]
        : '';

    try {
      if (token != null) {
        await CartService.addToWooCart(token, widget.productId, quantity);
      } else {
        await CartService.addItemToGuestCart(
          productId: widget.productId,
          title: product?['title'] ?? '',
          image: image,
          quantity: quantity,
          price: price,
          salePrice: salePrice,
          sku: product?['sku'] ?? '',
          category: product?['category'] ?? '',
        );
      }

      AlertService.showTopAlert(context, 'Ürün sepete eklendi',
          isError: false);
    } catch (e) {
      AlertService.showTopAlert(
          context, 'Sepete ekleme başarısız', isError: true);
    }
  }

  void _onSearchTap() {
    widget.onTabChange(1);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EntryPoint(
          onLocaleChange: widget.onLocaleChange,
          initialIndex: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ProductDetailsSkeleton();
    if (product == null) {
      return const Scaffold(
          body: Center(child: Text("Product not found.")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: CustomSearchAppBar(
        controller: TextEditingController(),
        onSearchTap: _onSearchTap,
        onBellTap: () {},
        onSearchSubmitted: (value) {},
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => fetchProductDetails(isRefresh: true),
              child: CustomScrollView(
                slivers: [
                  // Product Images + Wishlist Heart
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        ProductImages(
                          images: (product?['gallery'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                              [],
                          isBestSeller:
                          product?['is_best_seller'] == 1,
                        ),
                        // Back button
                        Positioned(
                          top: 16,
                          left: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.white70,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        // Wishlist Heart
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Consumer<WishlistProvider>(
                            builder: (context, wishlistProvider, _) {
                              final isInWishlist = wishlistProvider
                                  .isInWishlist(widget.productId);

                              return CircleAvatar(
                                backgroundColor: Colors.white70,
                                child: IconButton(
                                  icon: Icon(
                                    isInWishlist
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isInWishlist
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                  onPressed: () {
                                    final productData = {
                                      'id': widget.productId,
                                      'title':
                                      product?['title'] ?? '',
                                      'image': (product?['gallery']
                                      as List)
                                          .isNotEmpty
                                          ? product!['gallery'][0]
                                          : '',
                                      'price': price,
                                      'sale_price': salePrice,
                                      'sku': product?['sku'] ?? '',
                                      'category':
                                      product?['category'] ?? '',
                                    };
                                    wishlistProvider
                                        .toggleWishlist(productData);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product Info
                  ProductInfo(
                    category: product?['category'] ?? "Unknown Category",
                    sku: product?['sku'] ?? "Unknown SKU",
                    title: product?['title'] ?? "Unknown Title",
                    summaryName: product?['summary_name'] ?? "",
                    rating: (product?['rating'] as num?)?.toDouble() ?? 0.0,
                    numOfReviews: product?['num_of_reviews'] ?? 0,
                  ),

                  // Price + Quantity + Add to Cart
                  if (price > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (salePrice != null && salePrice! < price)
                              Row(
                                children: [
                                  Text(
                                    "$currencySymbol${price.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      decoration: TextDecoration
                                          .lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$currencySymbol${salePrice!.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                "$currencySymbol${price.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade400),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() => quantity =
                                              (quantity - 1)
                                                  .clamp(1, 999));
                                        },
                                        icon: const Icon(Icons.remove,
                                            color: primaryColor),
                                        visualDensity:
                                        VisualDensity.compact,
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue:
                                          quantity.toString(),
                                          textAlign: TextAlign.center,
                                          keyboardType:
                                          TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          decoration:
                                          const InputDecoration(
                                            contentPadding:
                                            EdgeInsets.symmetric(
                                                vertical: 8),
                                            isDense: true,
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) {
                                            final intValue =
                                            int.tryParse(value);
                                            if (intValue != null &&
                                                intValue > 0) {
                                              setState(() => quantity =
                                                  intValue.clamp(
                                                      1, 999));
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() => quantity += 1);
                                        },
                                        icon: const Icon(Icons.add,
                                            color: primaryColor),
                                        visualDensity:
                                        VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isInStock
                                        ? _handleAddToCart
                                        : null,
                                    icon: const Icon(Icons.shopping_cart),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isInStock
                                          ? primaryColor
                                          : Colors.grey,
                                      padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    label: Text(
                                      isInStock
                                          ? "Sepete Ekle"
                                          : "Stokta Yok",
                                      style:
                                      const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Attributes
                  if ((product?['attributes'] ?? []).isNotEmpty)
                    ExpandableSection(
                      title: "Özellikler",
                      initiallyExpanded: true,
                      leadingIcon: Icons.category,
                      iconColor: primaryColor,
                      child: ProductAttributes(
                        attributes: Map<String, List<String>>.from(
                            product?['attributes']),
                      ),
                    ),

                  // Description
                  ExpandableSection(
                    title: "Açıklama",
                    leadingIcon: Icons.description,
                    iconColor: primaryColor,
                    child: Html(
                      data: product?['description'] ??
                          "<p>No description available.</p>",
                      style: {
                        "body": Style(
                            fontSize: FontSize(13.0),
                            lineHeight: const LineHeight(1.6)),
                        "p": Style(color: Colors.black87),
                        "li": Style(color: Colors.black87),
                        "ul": Style(
                            padding: HtmlPaddings.only(left: 25)),
                      },
                    ),
                  ),

                  // Related Products
                  SliverToBoxAdapter(
                    child: RelatedProducts(productId: widget.productId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        onTap: (index) {
          widget.onTabChange(index);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EntryPoint(
                onLocaleChange: widget.onLocaleChange,
                initialIndex: index,
              ),
            ),
          );
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Anasayfa"),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: "Keşfet"),
          BottomNavigationBarItem(
              icon: Icon(Icons.store), label: "Mağaza"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: "Sepet"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}