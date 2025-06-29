import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import '../../../../components/product/product_card_horizontal.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmulatorProducts extends StatefulWidget {
  const EmulatorProducts({super.key});

  @override
  State<EmulatorProducts> createState() => _EmulatorProductsState();
}

class _EmulatorProductsState extends State<EmulatorProducts> {
  static final Map<String, List<ProductModel>> _cache = {};

  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != locale) {
      _currentLocale = locale;

      if (_cache.containsKey(locale)) {
        setState(() {
          products = _cache[locale]!;
          isLoading = false;
        });
      } else {
        fetchProducts(locale);
      }
    }
  }

  Future<void> fetchProducts(String locale) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await ApiService.fetchEmulatorProducts(locale);
      if (!mounted) return;

      setState(() {
        products = response;
        _cache[locale] = response;
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

    final groupedProducts = <List<ProductModel>>[];
    for (int i = 0; i < products.length; i += 2) {
      final group = products.skip(i).take(2).toList();
      groupedProducts.add(group);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Emülatörler",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () {
                  // Navigator.pushNamed(context, '/emulators');
                },
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
          VisibilityDetector(
            key: const Key('emulator-products'),
            onVisibilityChanged: (_) {},
            child: SizedBox(
              height: 325,
              child: Container(
                color: const Color(0xFFEAF2F4),
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
                              title: product.title,
                              price: product.price,
                              salePrice: product.salePrice,
                              dicountpercent: product.discountPercent,
                              sku: product.sku,
                              rating: product.rating,
                              discount: product.discount,
                              freeShipping: product.freeShipping,
                              isNew: product.isNew,
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
          ),
      ],
    );
  }
}