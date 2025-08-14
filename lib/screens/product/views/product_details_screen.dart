import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/product/views/components/product_attributes.dart';
import '../../../components/product/related_products.dart';
import '../../../components/skleton/product/product_details_skeleton.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/alert_service.dart';
import '../../../components/common/app_bar.dart';
import '../../../components/common/drawer.dart';
import '../../../providers/wishlist_provider.dart';
import 'components/expandable_section.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
// ✅ Category screen link
import 'package:shop/screens/category/category_products_screen.dart';

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

  static const int homeIndex = 0;
  static const int searchIndex = 1;
  static const int storeIndex = 2;
  static const int cartIndex = 3;
  static const int profileIndex = 4;

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
  bool _hasFetchedOnce = false;
  bool _isLoggedIn = false; // ✅ New state

  final TextEditingController _qtyController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // ✅ Check login status at start
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getString('auth_token') != null;
    });
  }

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

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> saveRecentlyViewedProduct() async {
    if (product == null) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> recentProducts = prefs.getStringList('recently_viewed') ?? [];

    Map<String, dynamic> productData = {
      'id': widget.productId,
      'image': (product?['gallery'] as List).isNotEmpty ? product!['gallery'][0] : '',
      'category': product?['category'] ?? '',
      'title': product?['title'] ?? '',
      'price': price,
      'salePrice': salePrice,
      'discountPercent': product?['discount_percent'],
      'sku': product?['sku'] ?? '',
      'rating': product?['rating'] ?? 0,
      'discount': product?['discount'],
      'freeShipping': product?['free_shipping'],
      'isNew': product?['is_new'] ?? false,
      'isInStock': isInStock,
      'currencySymbol': currencySymbol
    };

    String productJson = jsonEncode(productData);

    recentProducts.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['id'] == widget.productId;
    });

    recentProducts.insert(0, productJson);

    if (recentProducts.length > 10) {
      recentProducts = recentProducts.sublist(0, 10);
    }

    await prefs.setStringList('recently_viewed', recentProducts);
  }

  Future<void> fetchProductDetails({bool isRefresh = false}) async {
    if (_hasFetchedOnce && !isRefresh) return;
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
        currencySymbol = data['currency_symbol'] ?? '₺';
        isLoading = false;
        _hasFetchedOnce = true;
      });

      await saveRecentlyViewedProduct();
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _handleAddToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final image = (product?['gallery'] as List).isNotEmpty ? product!['gallery'][0] : '';

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
      AlertService.showTopAlert(
        context,
        'Ürün sepete eklendi',
        isError: false,
        showGoToCart: true,
      );
    } catch (_) {
      AlertService.showTopAlert(context, 'Sepete ekleme başarısız', isError: true);
    }
  }

  void _updateQuantity(int change) {
    final newQty = (quantity + change).clamp(1, 999);
    setState(() {
      quantity = newQty;
      _qtyController.text = newQty.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) return const ProductDetailsSkeleton();
    if (product == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text("Product not found.", style: theme.textTheme.bodyMedium),
        ),
      );
    }

    final int? categoryId = (product?['category_id'] ?? product?['categoryId']) is int
        ? (product?['category_id'] ?? product?['categoryId']) as int
        : int.tryParse("${product?['category_id'] ?? product?['categoryId'] ?? ''}");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CustomDrawer(),
      appBar: CustomSearchAppBar(
        controller: TextEditingController(),
        onSearchTap: () {
          widget.onTabChange(ProductDetailsScreen.searchIndex);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EntryPoint(
                onLocaleChange: widget.onLocaleChange,
                initialIndex: ProductDetailsScreen.searchIndex,
              ),
            ),
          );
        },
        onBellTap: () {},
        onSearchSubmitted: (_) {},
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => fetchProductDetails(isRefresh: true),
          child: CustomScrollView(
            slivers: [
              // ✅ Image
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? Colors.white
                                : theme.cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ProductImages(
                              images: (product?['gallery'] as List<dynamic>?)
                                  ?.map((e) => e.toString())
                                  .toList() ??
                                  [],
                              isBestSeller: product?['is_best_seller'] == 1,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: theme.cardColor.withOpacity(0.9),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlistProvider, _) {
                            final isInWishlist =
                            wishlistProvider.isInWishlist(widget.productId);
                            return CircleAvatar(
                              backgroundColor: theme.cardColor.withOpacity(0.9),
                              child: IconButton(
                                icon: Icon(
                                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                                  color: isInWishlist ? Colors.red : theme.iconTheme.color,
                                ),
                                onPressed: () {
                                  final productData = {
                                    'id': widget.productId,
                                    'title': product?['title'] ?? '',
                                    'image': (product?['gallery'] as List).isNotEmpty
                                        ? product!['gallery'][0]
                                        : '',
                                    'price': price,
                                    'sale_price': salePrice,
                                    'sku': product?['sku'] ?? '',
                                    'category': product?['category'] ?? '',
                                  };
                                  wishlistProvider.toggleWishlist(productData);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Category
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : theme.cardColor,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor.withOpacity(0.35)),
                      bottom: BorderSide(color: theme.dividerColor.withOpacity(0.35)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (categoryId != null && categoryId > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProductsScreen(
                              id: categoryId,
                              title: product?['category'] ?? '',
                              filterType: "category",
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product?['category'] ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              ProductInfo(
                sku: product?['sku'] ?? "",
                title: product?['title'] ?? "",
                summaryName: product?['summary_name'] ?? "",
              ),

              // ✅ Price section only if logged in
              if (price > 0 && _isLoggedIn)
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
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "$currencySymbol${salePrice!.toStringAsFixed(2)}",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            "$currencySymbol${price.toStringAsFixed(2)}",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? Colors.white
                                    : theme.cardColor,
                                border: Border.all(
                                    color: theme.dividerColor.withOpacity(0.8)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _updateQuantity(-1),
                                    icon: const Icon(Icons.remove),
                                    color: primaryColor,
                                  ),
                                  SizedBox(
                                    width: 54,
                                    child: TextField(
                                      controller: _qtyController,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        final val = int.tryParse(value);
                                        if (val != null && val > 0) {
                                          setState(() => quantity = val);
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                      ),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _updateQuantity(1),
                                    icon: const Icon(Icons.add),
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: isInStock ? _handleAddToCart : null,
                                  icon: const Icon(Icons.shopping_cart),
                                  label: Text(isInStock ? "Sepete Ekle" : "Stokta Yok"),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              if ((product?['attributes'] ?? []).isNotEmpty)
                ExpandableSection(
                  title: "Özellikler",
                  leadingIcon: Icons.category,
                  iconColor: primaryColor,
                  child: ProductAttributes(
                    attributes:
                    Map<String, List<String>>.from(product?['attributes']),
                  ),
                ),

              ExpandableSection(
                title: "Açıklama",
                leadingIcon: Icons.description,
                iconColor: primaryColor,
                child: Html(
                    data: product?['description'] ?? "<p>Bilgi yok</p>"),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: RelatedProducts(productId: widget.productId),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor:
          theme.bottomNavigationBarTheme.backgroundColor ??
              theme.cardColor,
          currentIndex: ProductDetailsScreen.storeIndex,
          onTap: (index) {
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
          unselectedItemColor: theme.unselectedWidgetColor,
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
      ),
    );
  }
}
