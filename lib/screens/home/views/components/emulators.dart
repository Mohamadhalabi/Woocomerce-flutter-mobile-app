import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shop/components/product/product_card.dart';
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
  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final response = await ApiService.fetchEmulatorProducts(locale);
      if (!mounted) return; // ✅ Ensure widget is still in the tree
      setState(() {
        products = response;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // ✅ Prevent error update on disposed widget
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Group products in pairs (2 items per column)
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
                child: Text(AppLocalizations.of(context)!.viewAll),
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
            onVisibilityChanged: (VisibilityInfo visibilityInfo) {
              double visiblePercentage = visibilityInfo.visibleFraction * 100;
              // You can handle analytics or tracking here
            },
            child: SizedBox(
              height: 325, // Enough for two rows
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