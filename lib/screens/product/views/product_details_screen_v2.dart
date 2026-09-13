// lib/screens/product/views/product_details_screen_v2.dart
//
// Product page on the new API.
//
// Differences from the original:
//   - addressed by SLUG, not an integer id
//   - `images` is a flat list of URL strings (the old one read img['src'])
//   - `content` is the description field, and it's raw HTML
//   - price visibility comes from the server, not from a local token check
//   - `purchasable` and `max_quantity` gate the add-to-cart button
//   - there's no `table_price` — that feature has no backend equivalent

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../../../components/common/app_bar.dart';
import '../../../components/common/drawer_v2.dart';
import '../../../components/product/catalog_product_card.dart';
import '../../../components/skleton/product/product_details_skeleton.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';
import '../../../models/catalog_product.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../route/route_constants.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../../services/cart_actions.dart';
import '../../../services/recently_viewed_service.dart';
import '../../category/category_products_screen_v2.dart';
import 'components/expandable_section.dart';
import 'components/product_images.dart';

class ProductDetailsScreenV2 extends StatefulWidget {
  const ProductDetailsScreenV2({
    super.key,
    required this.slug,
    this.onLocaleChange,
  });

  final String slug;
  final Function(String)? onLocaleChange;

  static const int searchIndex = 1;
  static const int storeIndex = 2;

  @override
  State<ProductDetailsScreenV2> createState() => _ProductDetailsScreenV2State();
}

class _ProductDetailsScreenV2State extends State<ProductDetailsScreenV2> {
  ProductDetail? _product;
  List<ProductModel> _related = [];

  bool _loading = true;
  String? _error;
  int _quantity = 1;

  /// 0 = Açıklama, 1 = Özellikler. Matches the website's tab pair.
  int _tab = 0;

  final TextEditingController _qtyController =
  TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final product = await catalogRepo.product(widget.slug);
      if (!mounted) return;

      setState(() {
        _product = product;
        _loading = false;
      });

      // Stored in ProductCardResource's shape so the Keşfet screen can render
      // a real product card from it.
      RecentlyViewedService.add({
        'id': product.id,
        'title': product.title,
        'slug': product.slug,
        'sku': product.sku,
        'price_visible': product.priceVisible,
        'price': product.price,
        'old_price': product.oldPrice,
        'discount': product.discount,
        'currency': {
          'code': product.currency.code,
          'symbol': product.currency.symbol,
          'rate': product.currency.rate,
        },
        'in_stock': product.inStock,
        'thumb': product.primaryImage,
        'badges': product.badges.map((b) => b.toJson()).toList(),
        'category': product.categories.isNotEmpty
            ? product.categories.first.name
            : null,
      });

      // Loaded after the page renders — related products are decorative and
      // shouldn't hold up the main content.
      final related = await catalogRepo.related(widget.slug);
      if (!mounted) return;
      setState(() => _related = related);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 404 ? 'Ürün bulunamadı.' : e.message;
        _loading = false;
      });
    }
  }

  /// A zero price means "not for sale at this price" rather than free — the
  /// detail endpoint returns 0.00 where the list endpoint returns null, so
  /// both have to be treated as hidden.
  bool get _showPrice {
    final product = _product;
    return product != null &&
        product.priceVisible &&
        product.price != null &&
        product.price! > 0;
  }

  /// The API caps quantity per product: null means unlimited (pre-order,
  /// backorders, or stock not tracked).
  int get _maxQuantity => _product?.maxQuantity ?? 999;

  void _updateQuantity(int change) {
    final next = (_quantity + change).clamp(1, _maxQuantity);
    setState(() {
      _quantity = next;
      _qtyController.text = next.toString();
    });
  }

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null) return;

    await CartActions.add(
      context,
      productId: product.id,
      quantity: _quantity,
    );
  }

  // ─── UI helpers, carried over from the original ───────────────────────────

  Widget _roundBack(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return CircleAvatar(
      backgroundColor:
      isDark ? const Color(0xFF2C2C2C) : theme.cardColor.withOpacity(0.9),
      child: IconButton(
        icon: Icon(Icons.arrow_back,
            color: isDark ? Colors.white : theme.iconTheme.color),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _chip({
    required String label,
    required VoidCallback onTap,
    Color? fg,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final foreground =
        fg ?? (isDark ? Colors.white : theme.colorScheme.primary);
    final background = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final border = borderColor ??
        (isDark ? Colors.white24 : theme.colorScheme.primary.withOpacity(0.45));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: foreground),
          ],
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 20,
        thickness: 1,
        color: isDark ? Colors.white24 : theme.dividerColor.withOpacity(0.35),
      ),
    );
  }

  Color _badgeColor(String key) {
    switch (key) {
      case 'sale':
        return Colors.red;
      case 'new':
        return Colors.green;
      case 'free_shipping':
        return Colors.blue;
      case 'preorder':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) return const ProductDetailsSkeleton();

    if (_product == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error ?? 'Ürün bulunamadı.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final category =
    product.categories.isNotEmpty ? product.categories.first : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CustomDrawerV2(),
      appBar: CustomSearchAppBar(
        controller: TextEditingController(),
        onSearchTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EntryPoint(
                onLocaleChange: widget.onLocaleChange ?? (_) {},
                initialIndex: ProductDetailsScreenV2.searchIndex,
              ),
            ),
          );
        },
        onBellTap: () =>
            Navigator.pushNamed(context, notificationsScreenRoute),
        onSearchSubmitted: (_) {},
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // Back + category chip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      _roundBack(context),
                      const SizedBox(width: 6),
                      if (category != null)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _chip(
                                  label: fixHtml(category.name),
                                  fg: isDark ? Colors.white : primaryColor,
                                  borderColor:
                                  isDark ? Colors.white24 : primaryColor,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CategoryProductsScreenV2(
                                            categorySlug: category.slug,
                                            title: fixHtml(category.name),
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Gallery + wishlist
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                            isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                            // Already a flat list of URLs — no img['src'] to
                            // unwrap the way the Woo payload needed.
                            child: ProductImages(images: product.images),
                          ),
                        ),
                      ),

                      if (product.badges.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: product.badges
                                .map((b) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _badgeColor(b.key),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                b.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                        ),

                      Positioned(
                        top: 8,
                        right: 10,
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlist, _) {
                            final isInWishlist =
                            wishlist.isInWishlist(product.id);
                            return CircleAvatar(
                              backgroundColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : theme.cardColor.withOpacity(0.9),
                              child: IconButton(
                                icon: Icon(
                                  isInWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isInWishlist
                                      ? Colors.red
                                      : (isDark
                                      ? Colors.white
                                      : theme.iconTheme.color),
                                ),
                                onPressed: () {
                                  wishlist.toggleWishlist({
                                    'id': product.id,
                                    'title': product.title,
                                    'image': product.primaryImage ?? '',
                                    'price': product.price ?? 0,
                                    'sale_price':
                                    product.oldPrice != null
                                        ? product.price
                                        : null,
                                    'sku': product.sku,
                                    'category': category?.name ?? '',
                                  });
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

              SliverToBoxAdapter(child: _sectionDivider()),

              // Title, SKU, brands
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (product.sku.isNotEmpty)
                        Text(
                          product.sku,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isDark ? Colors.white70 : primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (product.brands.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.brands.map((brand) {
                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryProductsScreenV2(
                                    brandSlug: brand.slug,
                                    title: brand.name,
                                  ),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : theme.dividerColor.withOpacity(0.35),
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  brand.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : primaryColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              // Price, quantity, add to cart
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The server decides whether prices are visible — no
                      // local token check.
                      if (_showPrice) ...[
                        if (product.oldPrice != null)
                          Row(
                            children: [
                              Text(
                                product.formattedOldPrice,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color:
                                  isDark ? Colors.white54 : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                product.formattedPrice,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: isDark ? Colors.white : primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _kdvSuffix(theme, isDark),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                product.formattedPrice,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: isDark ? Colors.white : primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _kdvSuffix(theme, isDark),
                            ],
                          ),
                      ] else
                        Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 18,
                                color:
                                isDark ? Colors.white70 : Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              "Fiyatı görmek için giriş yapın",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),

                      if (product.isPreorder &&
                          product.preorderReleaseDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Tahmini teslim: '
                                '${product.preorderReleaseDate!.day}.'
                                '${product.preorderReleaseDate!.month}.'
                                '${product.preorderReleaseDate!.year}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : theme.dividerColor.withOpacity(0.8),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => _updateQuantity(-1),
                                  icon: const Icon(Icons.remove),
                                  color: isDark ? Colors.white : primaryColor,
                                ),
                                SizedBox(
                                  width: 54,
                                  child: TextField(
                                    controller: _qtyController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final parsed = int.tryParse(value);
                                      if (parsed != null && parsed > 0) {
                                        setState(() => _quantity =
                                            parsed.clamp(1, _maxQuantity));
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                    style:
                                    theme.textTheme.titleMedium?.copyWith(
                                      color:
                                      isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _updateQuantity(1),
                                  icon: const Icon(Icons.add),
                                  color: isDark ? Colors.white : primaryColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                // `purchasable` accounts for pre-order and
                                // backorders, so it's the right gate — not
                                // in_stock on its own.
                                onPressed:
                                product.purchasable ? _addToCart : null,
                                icon: const Icon(Icons.shopping_cart),
                                label: Text(
                                  product.purchasable
                                      ? (product.isPreorder
                                      ? "Ön Sipariş Ver"
                                      : "Sepete Ekle")
                                      : "Stokta Yok",
                                ),
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

              // Açıklama / Özellikler tabs, same pair as the website.
              SliverToBoxAdapter(child: _detailTabs(product)),

              if (product.faq.isNotEmpty)
                ExpandableSection(
                  title: "Sık Sorulan Sorular",
                  leadingIcon: Icons.help_outline,
                  iconColor: isDark ? Colors.white : primaryColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: product.faq
                        .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.question,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(item.answer),
                        ],
                      ),
                    ))
                        .toList(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: _relatedRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color:
          theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.cardColor,
          currentIndex: ProductDetailsScreenV2.storeIndex,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EntryPoint(
                  onLocaleChange: widget.onLocaleChange ?? (_) {},
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
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }

  /// Catalogue prices are stored NET — OrderController adds 20% KDV at
  /// checkout — so the displayed figure is before tax, same as the website.
  Widget _kdvSuffix(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 2),
      child: Text(
        '+ KDV',
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDark ? Colors.white70 : primaryColor.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Tab header + the selected panel. Built as a plain Column rather than a
  /// TabBarView because that needs a bounded height, which it can't get inside
  /// a CustomScrollView.
  Widget _detailTabs(ProductDetail product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
    isDark ? Colors.white24 : theme.dividerColor.withOpacity(0.5);

    Widget tabButton(String label, int index) {
      final selected = _tab == index;

      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? primaryColor : borderColor,
                  width: selected ? 2.5 : 1,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : primaryColor)
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ),
        ),
      );
    }

    final hasSpecs = product.brands.isNotEmpty ||
        product.manufacturers.isNotEmpty ||
        product.attributes.any((a) => a.values.isNotEmpty);

    // Empty HTML still arrives as markup sometimes ("<p></p>", "&nbsp;"), so
    // the tags are stripped before deciding whether there's anything to show.
    final description = product.contentHtml ?? '';
    final hasDescription = description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', '')
        .trim()
        .isNotEmpty;

    // Nothing to show in either tab — render nothing at all rather than an
    // empty tab bar over "Bilgi yok".
    if (!hasDescription && !hasSpecs) return const SizedBox.shrink();

    // With only one of the two, the tab bar is pointless: show that panel on
    // its own under a plain heading.
    final singleTab = !hasDescription || !hasSpecs;

    // The description tab can't be selected when there's no description.
    final showDescription = hasDescription && (_tab == 0 || !hasSpecs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (singleTab)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primaryColor, width: 2.5),
                ),
              ),
              child: Text(
                hasDescription ? 'Açıklama' : 'Özellikler',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
            )
          else
            Row(
              children: [
                tabButton('Açıklama', 0),
                tabButton('Özellikler', 1),
              ],
            ),
          const SizedBox(height: 12),
          if (showDescription)
            Html(
              // `content`, not `description` — it contains real tables of
              // vehicle compatibility, so it needs the HTML renderer.
              data: description,
              style: {
                "body": Style(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: FontSize(15.0),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(color: isDark ? Colors.white : Colors.black),
                "td": Style(color: isDark ? Colors.white : Colors.black),
                "th": Style(color: isDark ? Colors.white : Colors.black),
                "li": Style(color: isDark ? Colors.white : Colors.black),
              },
            )
          else
            _specifications(product),
        ],
      ),
    );
  }

  /// Marka plus each attribute, as rows. Matches the table the website shows
  /// under the product title.
  Widget _specifications(ProductDetail product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rows = <MapEntry<String, String>>[
      if (product.brands.isNotEmpty)
        MapEntry('Marka', product.brands.map((b) => b.name).join(', ')),
      if (product.manufacturers.isNotEmpty)
        MapEntry('Üretici', product.manufacturers.map((m) => m.name).join(', ')),
      for (final attr in product.attributes)
        if (attr.values.isNotEmpty) MapEntry(attr.name, attr.values.join(', ')),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    final borderColor =
    isDark ? Colors.white24 : theme.dividerColor.withOpacity(0.5);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: borderColor)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey.shade50,
                      child: Text(
                        '${rows[i].key}:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(
                          rows[i].value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _relatedRow() {
    if (_related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            "Benzer Ürünler",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 310,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _related.length,
            itemBuilder: (context, i) {
              final item = _related[i];
              return CatalogProductCard(
                product: item,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreenV2(slug: item.slug),
                  ),
                ),
                onAddToCart: (qty) =>
                    CartActions.addProduct(context, item, quantity: qty),
              );
            },
          ),
        ),
      ],
    );
  }
}