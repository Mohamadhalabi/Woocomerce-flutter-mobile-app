import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/skleton/skelton.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/product/views/components/product_attributes.dart';
import '../../../components/product/related_products.dart';
import '../../../services/api_service.dart';
import '../../../services/cart_service.dart';
import 'components/expandable_section.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import '../../../services/alert_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.onLocaleChange,
  });

  final int productId;
  final Function(String) onLocaleChange;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != locale) {
      _currentLocale = locale;
      fetchProductDetails();
    }
  }

  Future<void> fetchProductDetails() async {
    if (_currentLocale == null) return;
    setState(() => isLoading = true);

    try {
      final result = await ApiService.fetchProductById(widget.productId, _currentLocale!);
      final data = result.toJson();
      setState(() {
        product = data;
        price = (data['price'] as num?)?.toDouble() ?? 0.0;
        salePrice = data['sale_price'] != null ? (data['sale_price'] as num).toDouble() : null;
        isInStock = data['stock_status'] == 'instock';
        currencySymbol = data['currency_symbol'] ?? '₺'; // ✅ Add this line
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _handleAddToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final image = (product!['gallery'] as List).isNotEmpty ? product!['gallery'][0] : '';

    try {
      if (token != null) {
        await CartService.addToWooCart(token, widget.productId, quantity);
      } else {
        await CartService.addItemToGuestCart(
          productId: widget.productId,
          title: product!['title'] ?? '',
          image: image,
          quantity: quantity,
          price: price,
          salePrice: salePrice,
          sku: product!['sku'] ?? '',
        );
      }

      AlertService.showTopAlert(context, 'Ürün sepete eklendi', isError: false);
    } catch (e) {
      AlertService.showTopAlert(context, 'Sepete ekleme başarısız', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: Skeleton()));
    }

    if (product == null) {
      return const Scaffold(body: Center(child: Text("Product not found.")));
    }

    return Scaffold(
      appBar: AppBar(title: Text(product!['title'])),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchProductDetails,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                automaticallyImplyLeading: false,
                floating: true,
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      "assets/icons/Bookmark.svg",
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              ProductImages(
                images: (product!['gallery'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                    [],
                isBestSeller: product!['is_best_seller'] == 1,
              ),
              ProductInfo(
                category: product!['category'] ?? "Unknown Category",
                sku: product!['sku'] ?? "Unknown SKU",
                title: product!['title'] ?? "Unknown Title",
                summaryName: product!['summary_name'] ?? "",
                rating: (product!['rating'] as num?)?.toDouble() ?? 0.0,
                numOfReviews: product!['num_of_reviews'] ?? 0,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                decoration: TextDecoration.lineThrough,
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
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() => quantity = (quantity - 1).clamp(1, 999));
                                  },
                                  icon: const Icon(Icons.remove, color: primaryColor),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => quantity += 1);
                                  },
                                  icon: const Icon(Icons.add, color: primaryColor),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isInStock ? _handleAddToCart : null,
                              icon: const Icon(Icons.shopping_cart),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isInStock ? primaryColor : Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              label: Text(
                                isInStock ? "Sepete Ekle" : "Stokta Yok",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if ((product!['attributes'] ?? {}).isNotEmpty)
                ExpandableSection(
                  title: "Özellikler",
                  initiallyExpanded: true,
                  leadingIcon: Icons.category,
                  child: ProductAttributes(
                    attributes: (product!['attributes'] as Map<String, dynamic>),
                  ),
                ),
              ExpandableSection(
                title: "Açıklama",
                leadingIcon: Icons.description,
                child: Html(
                  data: product!['description'] ?? "<p>No description available.</p>",
                  style: {
                    "body": Style(fontSize: FontSize(13.0), lineHeight: const LineHeight(1.6)),
                    "p": Style(color: Colors.black87),
                    "li": Style(color: Colors.black87),
                    "ul": Style(padding: HtmlPaddings.only(left: 25)),
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: RelatedProducts(productId: widget.productId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}