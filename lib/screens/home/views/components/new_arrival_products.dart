import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/providers/currency_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NewArrivalProducts extends StatefulWidget {
  final int refreshCounter;
  final VoidCallback? onViewAll;

  const NewArrivalProducts({
    super.key,
    required this.refreshCounter,
    this.onViewAll,
  });

  @override
  State<NewArrivalProducts> createState() => _NewArrivalProductsState();
}

class _NewArrivalProductsState extends State<NewArrivalProducts> {
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
      final locale = Localizations.localeOf(context).languageCode;
      final currency = Provider.of<CurrencyProvider>(context, listen: false).selectedCurrency;
      _cacheKey = '$locale|$currency';

      if (_cachedProductsByLocaleAndCurrency.containsKey(_cacheKey)) {
        setState(() {
          products = _cachedProductsByLocaleAndCurrency[_cacheKey]!;
          hasLoaded = true;
          isLoading = false;
        });
      } else {
        fetchProducts(locale, currency);
      }
    }
  }

  @override
  void didUpdateWidget(covariant NewArrivalProducts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshCounter != _lastRefresh) {
      _lastRefresh = widget.refreshCounter;
      hasLoaded = false;
      if (isVisible) {
        final locale = Localizations.localeOf(context).languageCode;
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
      final response = await ApiService.fetchLatestProducts(locale);
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
    final t = AppLocalizations.of(context)!;

    return VisibilityDetector(
      key: const Key('new-arrival-products'),
      onVisibilityChanged: _handleVisibility,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.newArrival,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: widget.onViewAll,
                  child: Text(t.viewAll),
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
              height: 290,
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).cardColor.withOpacity(0.1)
                    : const Color(0xFFEAF2F4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: defaultPadding,
                        right: index == products.length - 1 ? defaultPadding : 0,
                      ),
                      child: ProductCard(
                        id: product.id,
                        image: product.image,
                        category: product.category,
                        title: product.title,
                        price: product.price,
                        salePrice: product.salePrice,
                        sku: product.sku,
                        rating: product.rating,
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
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}