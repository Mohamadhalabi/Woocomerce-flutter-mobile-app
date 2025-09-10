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
  bool _isLoggedIn = false;

  final TextEditingController _qtyController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
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
      if (!_hasFetchedOnce) fetchProductDetails();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  // ---------- helpers to normalize payload differences ----------
  String _titleOf(Map<String, dynamic> p) =>
      (p['title']?.toString().trim().isNotEmpty ?? false)
          ? p['title'].toString()
          : (p['name']?.toString() ?? '');

  List<String> _imageUrlsOf(Map<String, dynamic> p) {
    final raw = (p['gallery'] ?? p['images']) as List<dynamic>? ?? const [];
    return raw
        .map((e) {
      if (e is String) return e;
      if (e is Map && e['src'] != null) return e['src'].toString();
      return '';
    })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _firstCategory(Map<String, dynamic> p) {
    if (p['categories'] is List && (p['categories'] as List).isNotEmpty) {
      return Map<String, dynamic>.from(p['categories'][0] as Map);
    }
    if (p['category'] != null || p['category_id'] != null || p['categoryId'] != null) {
      return {
        'id': p['category_id'] ?? p['categoryId'],
        'name': p['category'],
      };
    }
    return null;
  }
  // -------------------------------------------------------------

  Future<void> saveRecentlyViewedProduct() async {
    if (product == null) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> recentProducts = prefs.getStringList('recently_viewed') ?? [];

    final imgs = _imageUrlsOf(product!);
    final productData = {
      'id': widget.productId,
      'image': imgs.isNotEmpty ? imgs.first : '',
      'category': _firstCategory(product!)?['name'] ?? '',
      'title': _titleOf(product!),
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

    final productJson = jsonEncode(productData);
    recentProducts.removeWhere((item) => (jsonDecode(item)['id'] == widget.productId));
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
      final data = result.toJson(); // requires ProductModel.toJson() to include 'brands'
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

    final imgs = product == null ? <String>[] : _imageUrlsOf(product!);
    final firstImg = imgs.isNotEmpty ? imgs.first : '';

    try {
      if (token != null) {
        await CartService.addToWooCart(token, widget.productId, quantity);
      } else {
        await CartService.addItemToGuestCart(
          productId: widget.productId,
          title: _titleOf(product ?? {}),
          image: firstImg,
          quantity: quantity,
          price: price,
          salePrice: salePrice,
          sku: product?['sku'] ?? '',
          category: _firstCategory(product ?? {})?['name'] ?? '',
        );
      }
      if (!mounted) return;
      AlertService.showTopAlert(
        context,
        'Ürün sepete eklendi',
        isError: false,
        showGoToCart: true,
      );
    } catch (_) {
      if (!mounted) return;
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

  // ——————————————————— UI HELPERS ———————————————————

  Widget _roundBack(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      backgroundColor: theme.cardColor.withOpacity(0.9),
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _chip({
    Widget? leading,
    required String label,
    required VoidCallback onTap,
    Color? fg,
    Color? bg,
    Color? borderColor,
    bool solid = false,
  }) {
    final theme = Theme.of(context);
    final Color _fg = fg ?? (solid ? Colors.white : theme.colorScheme.primary);
    final Color _bg = bg ??
        (solid
            ? theme.colorScheme.primary
            : (theme.brightness == Brightness.light
            ? Colors.white
            : theme.cardColor));
    final Color _bd = borderColor ??
        (solid ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.45));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _bd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _fg,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: _fg),
          ],
        ),
      ),
    );
  }

  Widget _sectionDivider({double indent = 16, double endIndent = 16}) {
    final theme = Theme.of(context);
    final base = theme.dividerColor;
    final color =
    theme.brightness == Brightness.dark ? base.withOpacity(0.6) : base.withOpacity(0.35);

    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Divider(height: 20, thickness: 1, color: color),
    );
  }

  // ——————————————————————————————————————————————————

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) return const ProductDetailsSkeleton();

    if (product == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: Text("Product not found.", style: theme.textTheme.bodyMedium)),
      );
    }

    // Category chip data (next to back button)
    final cat = _firstCategory(product!);
    final dynamic rawCatId = cat == null ? null : cat['id'];
    final int? categoryId =
    rawCatId is int ? rawCatId : (rawCatId == null ? null : int.tryParse(rawCatId.toString()));
    final String categoryName = (cat?['name']?.toString() ?? '').trim();

    // Brands: array of {id, name, slug, logo?}
    final List<Map<String, dynamic>> brands = (product!['brands'] is List)
        ? (product!['brands'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final images = _imageUrlsOf(product!);
    final title = _titleOf(product!);
    final sku = product?['sku']?.toString() ?? '';

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
              // TOP ROW: Back + Category (above image)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      _roundBack(context),
                      const SizedBox(width: 6),
                      if (categoryId != null && categoryId > 0 && categoryName.isNotEmpty)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _chip(
                                  label: categoryName,
                                  fg: primaryColor, // text & chevron = primary
                                  borderColor: primaryColor, // border = primary
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryProductsScreen(
                                          id: categoryId,
                                          title: categoryName,
                                          filterType: "category",
                                        ),
                                      ),
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
              ),

              // IMAGE + WISHLIST overlay
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                              images: images,
                            ),
                          ),
                        ),
                      ),
                      // ❤️ wishlist (top-right over image)
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlistProvider, _) {
                            final isInWishlist = wishlistProvider.isInWishlist(widget.productId);
                            return CircleAvatar(
                              backgroundColor: theme.cardColor.withOpacity(0.9),
                              child: IconButton(
                                icon: Icon(
                                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                                  color: isInWishlist ? Colors.red : theme.iconTheme.color,
                                ),
                                onPressed: () {
                                  final firstImg = images.isNotEmpty ? images.first : '';
                                  final productData = {
                                    'id': widget.productId,
                                    'title': title,
                                    'image': firstImg,
                                    'price': price,
                                    'sale_price': salePrice,
                                    'sku': sku,
                                    'category': categoryName,
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

              // clear separator
              const SliverToBoxAdapter(child: SizedBox(height: 0)),
              SliverToBoxAdapter(child: _sectionDivider()),

              // TITLE → SKU (primary) → BRANDS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title above SKU
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // SKU in primaryColor
                      if (sku.isNotEmpty)
                        Text(
                          sku,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Brands under SKU
                      if (brands.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: brands.map((b) {
                            final dynamic rawBid = b['id'];
                            final int bid = rawBid is int
                                ? rawBid
                                : (rawBid == null ? 0 : (int.tryParse(rawBid.toString()) ?? 0));
                            final String bname = b['name']?.toString() ?? '';
                            // final String logo = b['logo']?.toString() ?? '';

                            return InkWell(
                              onTap: () {
                                if (bid > 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryProductsScreen(
                                        id: bid,
                                        title: bname,
                                        filterType: "brand",
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.light
                                      ? Colors.white
                                      : theme.cardColor,
                                  border:
                                  Border.all(color: theme.dividerColor.withOpacity(0.35)),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 2),
                                    Text(
                                      bname,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              // PRICE + QTY (only if logged in)
// ==== PRICE (only when logged in) + QTY & ADD TO CART (always) ====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price area
                      if (_isLoggedIn) ...[
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
                      ] else ...[
                        // Logged-out hint (no numbers)
                        Row(
                          children: [
                            const Icon(Icons.lock_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Fiyatı görmek için giriş yapın",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Qty + Add to Cart (always visible)
                      Row(
                        children: [
                          // qty
                          Container(
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : theme.cardColor,
                              border: Border.all(color: theme.dividerColor.withOpacity(0.8)),
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
                          // add to cart
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
                child: Html(data: product?['description'] ?? "<p>Bilgi yok</p>"),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: RelatedProducts(productId: widget.productId)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
          boxShadow: [
            BoxShadow(
              color:
              theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor:
          theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mağaza"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }
}
