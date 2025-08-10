import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/search/views/components/search_form.dart';
import 'package:shop/screens/search/views/global_search_screen.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/route/route_constants.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  DiscoverScreenState createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  List<String> previousSearches = [];
  List<Map<String, dynamic>> recentlyViewedProducts = [];

  @override
  void initState() {
    super.initState();
    loadPreviousSearches();
    loadRecentlyViewed();
  }

  Future<void> refresh() async {
    await loadPreviousSearches();
    await loadRecentlyViewed();
  }

  Future<void> loadPreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      previousSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> loadRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final recentList = prefs.getStringList('recently_viewed') ?? [];

    setState(() {
      recentlyViewedProducts =
          recentList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final lowerQuery = query.toLowerCase();

    // Remove duplicates ignoring case
    List<String> updated = [
      query,
      ...previousSearches.where((q) => q.toLowerCase() != lowerQuery)
    ];

    if (updated.length > 10) updated = updated.sublist(0, 10);

    await prefs.setStringList('recent_searches', updated);
    setState(() => previousSearches = updated);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => previousSearches = []);
  }

  void handleSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    saveSearch(trimmed);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalSearchScreen(query: trimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return SafeArea(
      child: Container(
        color: isLightMode ? Colors.white : null, // White background in light mode
        child: RefreshIndicator(
          onRefresh: refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 Search bar
                Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: SearchForm(
                    onFieldSubmitted: (value) {
                      if (value != null) handleSearch(value);
                    },
                  ),
                ),

                // 📜 Previous Searches
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Önceki Aramalar",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (previousSearches.isNotEmpty)
                        TextButton(
                          onPressed: clearSearchHistory,
                          child: const Text("Temizle"),
                        ),
                    ],
                  ),
                ),

                if (previousSearches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Text("Henüz arama yapılmadı."),
                  )
                else
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: Wrap(
                      spacing: 8,
                      children: previousSearches.map((query) {
                        return ActionChip(
                          label: Text(query),
                          onPressed: () => handleSearch(query),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 20),

                // 🆕 Recently Viewed Products
                if (recentlyViewedProducts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: defaultPadding, vertical: 8),
                    child: Text(
                      "Son Görüntülenenler",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                      const EdgeInsets.symmetric(horizontal: defaultPadding),
                      itemCount: recentlyViewedProducts.length,
                      itemBuilder: (context, index) {
                        final product = recentlyViewedProducts[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 12,
                            right: index ==
                                recentlyViewedProducts.length - 1
                                ? 0
                                : 0,
                          ),
                          child: ProductCard(
                            id: product['id'],
                            image: product['image'] ?? '',
                            category: product['category'] ?? '',
                            title: product['title'] ?? '',
                            price: (product['price'] ?? 0).toDouble(),
                            salePrice: product['salePrice'] != null
                                ? (product['salePrice'] as num).toDouble()
                                : null,
                            dicountpercent: product['discountPercent'],
                            sku: product['sku'] ?? '',
                            rating: (product['rating'] ?? 0).toDouble(),
                            discount: product['discount'],
                            freeShipping:
                            product['freeShipping'] ?? false,
                            isNew: product['isNew'] ?? false,
                            isInStock:
                            product['isInStock'] ?? true,
                            currencySymbol:
                            product['currencySymbol'] ?? '₺',
                            press: () {
                              Navigator.pushNamed(
                                context,
                                productDetailsScreenRoute,
                                arguments: product['id'],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}