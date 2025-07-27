import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';

import '../../../constants.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  BookmarkScreenState createState() => BookmarkScreenState(); // Public state class
}

class BookmarkScreenState extends State<BookmarkScreen> {
  List<ProductModel> bookmarkedProducts = [];

  @override
  void initState() {
    super.initState();
    loadBookmarks(); // initial load
  }

  Future<void> refresh() async {
    await loadBookmarks(); // called from EntryPoint
  }

  Future<void> loadBookmarks() async {
    // 🟡 Replace this with your actual logic (e.g., SharedPreferences or WishlistProvider)
    // For demo purposes we use a static list
    // setState(() {
    //   bookmarkedProducts = demoPopularProducts;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (bookmarkedProducts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Text("Henüz favori ürün yok."),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200.0,
                  mainAxisSpacing: defaultPadding,
                  crossAxisSpacing: defaultPadding,
                  childAspectRatio: 0.66,
                ),
                delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    final product = bookmarkedProducts[index];
                    // return ProductCard(
                    //   id: product.id,
                    //   image: product.image,
                    //   category: product.category,
                    //   title: product.title,
                    //   price: product.price,
                    //   sku: "SKU",
                    //   rating: 4.5,
                    //   salePrice: product.salePrice,
                    //   dicountpercent: product.discountPercent,
                    //   press: () {
                    //     Navigator.pushNamed(
                    //       context,
                    //       productDetailsScreenRoute,
                    //       arguments: product.id,
                    //     );
                    //   },
                    // );
                  },
                  childCount: bookmarkedProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}