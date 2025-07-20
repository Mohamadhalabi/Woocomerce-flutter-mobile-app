import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/currency_provider.dart';

class FlashSaleProducts extends StatefulWidget {
  const FlashSaleProducts({super.key});

  @override
  State<FlashSaleProducts> createState() => _FlashSaleProductsState();
}

class _FlashSaleProductsState extends State<FlashSaleProducts> {
  static final Map<String, List<ProductModel>> _cachedProductsByLocaleAndCurrency = {};

  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";
  String _cacheKey = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locale = Localizations.localeOf(context).languageCode;
    final currency = Provider.of<CurrencyProvider>(context, listen: true).selectedCurrency;
    final newKey = '$locale|$currency';

    if (_cacheKey != newKey) {
      _cacheKey = newKey;

      if (_cachedProductsByLocaleAndCurrency.containsKey(_cacheKey)) {
        setState(() {
          products = _cachedProductsByLocaleAndCurrency[_cacheKey]!;
          isLoading = false;
        });
      } else {
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
      final response = await ApiService.fetchFlashSaleProducts(locale);
      if (!mounted) return;

      setState(() {
        products = response;
        _cachedProductsByLocaleAndCurrency[_cacheKey] = response;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.specialOffer, style: Theme.of(context).textTheme.titleSmall),
              TextButton(
                onPressed: () {},
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
              color: const Color(0xFFEAF2F4),
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                },
              ),
            ),
          ),
      ],
    );
  }
}