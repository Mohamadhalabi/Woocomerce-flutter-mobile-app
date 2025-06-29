import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NewArrivalProducts extends StatefulWidget {
  const NewArrivalProducts({super.key});

  @override
  State<NewArrivalProducts> createState() => _NewArrivalProductsState();
}

class _NewArrivalProductsState extends State<NewArrivalProducts> {
  static final Map<String, List<ProductModel>> _cachedProductsByLocale = {};
  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newLocale = Localizations.localeOf(context).languageCode;

    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;

      if (_cachedProductsByLocale.containsKey(newLocale)) {
        setState(() {
          products = _cachedProductsByLocale[newLocale]!;
          isLoading = false;
        });
      } else {
        fetchProducts(newLocale);
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
      final response = await ApiService.fetchLatestProducts(locale);
      if (!mounted) return;

      setState(() {
        products = response;
        _cachedProductsByLocale[locale] = response;
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
                onPressed: () {
                  // Navigator.pushNamed(context, '/new-arrival');
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
          SizedBox(
            height: 280,
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
          )
      ],
    );
  }
}