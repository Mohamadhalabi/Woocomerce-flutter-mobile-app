import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../components/product/product_card_horizontal.dart';
import '../../../../constants.dart';
import 'package:shop/providers/currency_provider.dart';

class EmulatorProducts extends StatefulWidget {
  final int refreshCounter;
  final VoidCallback? onViewAll;

  const EmulatorProducts({
    super.key,
    required this.refreshCounter,
    this.onViewAll,
  });

  @override
  State<EmulatorProducts> createState() => _EmulatorProductsState();
}

class _EmulatorProductsState extends State<EmulatorProducts> {
  static final Map<String, List<ProductModel>> _cachedProductsByLocaleAndCurrency = {};

  List<ProductModel> products = [];
  bool isLoading = false;
  String errorMessage = '';
  String _cacheKey = '';
  bool isVisible = false;
  bool hasLoaded = false;
  int _lastRefresh = -1;

  void _handleVisibility(VisibilityInfo info) {
    final visible = info.visibleFraction > 0.2;
    setState(() => isVisible = visible);

    if (visible && !hasLoaded) {
      // ✅ FIX: Force Turkish Locale
      const locale = 'tr';
      final currency = Provider.of<CurrencyProvider>(context, listen: false).selectedCurrency;
      _cacheKey = '$locale|$currency';

      if (_cachedProductsByLocaleAndCurrency.containsKey(_cacheKey)) {
        setState(() {
          products = _cachedProductsByLocaleAndCurrency[_cacheKey]!;
          isLoading = false;
          hasLoaded = true;
        });
      } else {
        fetchProducts(locale, currency);
      }
    }
  }

  @override
  void didUpdateWidget(covariant EmulatorProducts oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.refreshCounter != _lastRefresh) {
      _lastRefresh = widget.refreshCounter;
      hasLoaded = false; // allow re-fetch on scroll again
      if (isVisible) {
        // ✅ FIX: Force Turkish Locale
        const locale = 'tr';
        final currency = Provider.of<CurrencyProvider>(context, listen: false).selectedCurrency;
        fetchProducts(locale, currency);
      }
    }
  }

  Future<void> fetchProducts(String locale, String currency) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await ApiService.fetchEmulatorProducts(locale);
      if (!mounted) return;

      setState(() {
        products = response;
        _cachedProductsByLocaleAndCurrency[_cacheKey] = response;
        isLoading = false;
        hasLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        hasLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed: final t = AppLocalizations.of(context)!;

    final groupedProducts = <List<ProductModel>>[];
    for (int i = 0; i < products.length; i += 2) {
      groupedProducts.add(products.skip(i).take(2).toList());
    }

    return VisibilityDetector(
      key: const Key('emulator-products'),
      onVisibilityChanged: _handleVisibility,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const SizedBox(height: defaultPadding / 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Emülatörler", style: Theme.of(context).textTheme.titleSmall),
                TextButton(
                  onPressed: widget.onViewAll,
                  child: const Text("Tümünü Gör"), // ✅ FIX: Hardcoded Turkish
                ),
              ],
            ),
          ),
          if (isLoading)
            const Center(child: ProductsSkelton())
          else if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
            )
          else
            SizedBox(
              height: 350,
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).cardColor.withOpacity(0.1)
                    : const Color(0xFFEAF2F4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupedProducts.length,
                  itemBuilder: (context, index) {
                    final pair = groupedProducts[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: defaultPadding,
                        right: index == groupedProducts.length - 1 ? defaultPadding : 0,
                      ),
                      child: Column(
                        children: pair.map((product) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProductCardHorizontal(
                              id: product.id,
                              image: product.image,
                              category: product.category,
                              categoryId: product.categoryId,
                              title: product.title,
                              price: product.price,
                              salePrice: product.salePrice,
                              dicountpercent: product.discountPercent,
                              sku: product.sku,
                              rating: product.rating,
                              discount: product.discount,
                              freeShipping: product.freeShipping,
                              isNew: product.isNew,
                              isInStock: product.isInStock,
                              currencySymbol: product.currencySymbol,
                              press: () {
                                Navigator.pushNamed(
                                  context,
                                  productDetailsScreenRoute,
                                  arguments: product.id,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}