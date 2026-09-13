// lib/screens/home/views/home_screen_v2.dart
//
// The home screen on the new API. Same layout as the original:
//   categories -> slider -> Yeni Gelenler -> banner -> Fırsatlar -> Emülatörler
//
// One request on open: /home carries the slider, banners and Yeni Gelenler.
// Fırsatlar and Emülatörler fetch themselves when they scroll into view, since
// most sessions never reach them.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../components/product/add_to_cart_modal_v2.dart';
import '../../../components/product/catalog_product_card.dart';
import '../../../components/skleton/app_skeletons.dart';
import '../../../models/catalog_product.dart';
import '../../../repositories/catalog_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/home_repository.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../../services/currency_service.dart';
import '../../category/category_products_screen_v2.dart';
import '../../product/views/product_details_screen_v2.dart';
import 'components/categories_v2.dart';
import 'components/lazy_product_row.dart';
import 'components/offers_carousel_v2.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2>
    with AutomaticKeepAliveClientMixin {
  HomeData? _home;

  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();

    // This screen is kept alive inside an IndexedStack, so a currency switch
    // elsewhere never rebuilds it. Without this listener the prices stay in
    // the old currency until a manual pull-to-refresh.
    CurrencyService.revision.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    CurrencyService.revision.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final home = await homeRepo.fetchHome();

      if (!mounted) return;

      setState(() {
        _home = home;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _addToCart(ProductModel product, int quantity) =>
      AddToCartModalV2.show(context, product, initialQuantity: quantity);

  void _openProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreenV2(slug: product.slug),
      ),
    );
  }

  void _openCategory(CategoryNode category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreenV2(
          categorySlug: category.slug,
          title: category.name,
        ),
      ),
    );
  }

  /// Routes a slider or banner tap.
  ///
  /// Links are authored for the website, so they arrive as full URLs or paths
  /// rather than as a type + slug. The path segment is what identifies the
  /// destination: /urun/… is a product, /kategori/… or /magaza/… a category.
  void _openSlide(HomeSlide slide) {
    final link = slide.link?.trim();
    if (link == null || link.isEmpty) return;

    final path = Uri.tryParse(link)?.path ?? link;
    final segments =
    path.split('/').where((s) => s.trim().isNotEmpty).toList();

    if (segments.isEmpty) return;

    // The slug is the last segment; the one before it says what kind.
    final slug = segments.last;
    final kind = segments.length > 1 ? segments[segments.length - 2] : '';

    switch (kind) {
      case 'urun':
      case 'product':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreenV2(slug: slug),
          ),
        );
        return;

      case 'kategori':
      case 'category':
      case 'magaza':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreenV2(
              categorySlug: slug,
              title: slug,
            ),
          ),
        );
        return;

      case 'marka':
      case 'brand':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreenV2(
              brandSlug: slug,
              title: slug,
            ),
          ),
        );
        return;
    }

    // A bare slug with no prefix — treated as a category, which is what the
    // sliders in the admin currently point at.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreenV2(
          categorySlug: slug,
          title: slug,
        ),
      ),
    );
  }

  /// Opens the catalogue filtered the same way the row is.
  void _openAll({
    required String title,
    String? categorySlug,
    bool onSale = false,
    ProductBadgeFilter? badge,
    ProductSort? sort,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreenV2(
          categorySlug: categorySlug,
          onSale: onSale,
          badge: badge,
          sort: sort,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _error != null
              ? _errorView()
              : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loads its own data and caches it, so it survives the
                // product rows refreshing.
                CategoriesV2(onCategoryTap: _openCategory),

                OffersCarouselV2(
                  slides: _home?.hero ?? const [],
                  isLoading: _loading,
                  onSlideTap: _openSlide,
                ),

                if (_loading)
                  _skeleton()
                else ...[
                  const SizedBox(height: 20),

                  // Already in the /home payload — no extra request.
                  //
                  // "Tümünü Gör" sorts by newest rather than filtering on
                  // the `new` badge: the row is latest-by-id, and the
                  // badge needs is_new ticked in the admin, so the two
                  // return different products.
                  _productRow(
                    'Yeni Gelenler',
                    _home!.newProducts,
                    onViewAll: () => _openAll(
                      title: 'Yeni Gelenler',
                      sort: ProductSort.newest,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_home!.promos.isNotEmpty)
                    _banner(_home!.promos.first),

                  const SizedBox(height: 24),

                  LazyProductRow(
                    title: 'Fırsatlar',
                    cacheKey: 'onsale',
                    query: const ProductQuery(onSale: true, perPage: 12),
                    onViewAll: () =>
                        _openAll(title: 'Fırsatlar', onSale: true),
                  ),

                  const SizedBox(height: 24),

                  LazyProductRow(
                    title: 'Emülatörler',
                    cacheKey: 'emulatorler',
                    query: const ProductQuery(
                      category: 'emulatorler',
                      perPage: 12,
                    ),
                    onViewAll: () => _openAll(
                      title: 'Emülatörler',
                      categorySlug: 'emulatorler',
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_home!.banners.isNotEmpty)
                    _banner(_home!.banners.first),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorView() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 120),
      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
      const SizedBox(height: 12),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: ElevatedButton(
          onPressed: _load,
          child: const Text('Tekrar dene'),
        ),
      ),
    ],
  );

  /// Mirrors the real layout, so the page fills in place rather than snapping
  /// from a spinner.
  Widget _skeleton() => const Column(
    children: [
      BannerSkeleton(),
      SizedBox(height: 8),
      ProductRowSkeleton(),
      ProductRowSkeleton(),
    ],
  );

  /// Banners carry links just as the slider does — they were rendered as a
  /// plain Image, so a link set in the admin did nothing.
  Widget _banner(HomeSlide slide) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: GestureDetector(
      onTap: () => _openSlide(slide),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: slide.image,
          fit: BoxFit.fitWidth,
          placeholder: (_, __) => const BannerSkeleton(),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    ),
  );

  Widget _productRow(
      String title,
      List<ProductModel> products, {
        required VoidCallback onViewAll,
      }) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
        ),
        SizedBox(
          // Matches the 4-line title cards. Raising maxLines without raising
          // this is what causes the overflow stripes.
          height: 292,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: products.length,
            itemBuilder: (context, i) => CatalogProductCard(
              product: products[i],
              onTap: () => _openProduct(products[i]),
              onAddToCart: (qty) => _addToCart(products[i], qty),
            ),
          ),
        ),
      ],
    );
  }
}