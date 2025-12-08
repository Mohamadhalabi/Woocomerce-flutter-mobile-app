import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/search/views/components/search_form.dart';
import 'package:shop/screens/search/views/global_search_screen.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/product_card_skelton.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  DiscoverScreenState createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  // History & Recents
  List<String> previousSearches = [];
  List<Map<String, dynamic>> recentlyViewedProducts = [];

  // Live Search State
  Timer? _debounce;
  List<ProductModel> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = "";

  // Currency State
  String _currencySymbol = "₺"; // Default

  @override
  void initState() {
    super.initState();
    loadPreviousSearches();
    loadRecentlyViewed();
    _loadCurrencySymbol(); // <--- New: Load correct symbol
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- CURRENCY LOGIC ---
  Future<void> _loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('selected_currency') ?? 'TRY';

    setState(() {
      if (currencyCode == 'USD') _currencySymbol = '\$';
      else if (currencyCode == 'EUR') _currencySymbol = '€';
      else if (currencyCode == 'GBP') _currencySymbol = '£';
      else _currencySymbol = '₺';
    });
  }

  // --- EXISTING HISTORY LOGIC ---
  Future<void> refresh() async {
    await loadPreviousSearches();
    await loadRecentlyViewed();
    await _loadCurrencySymbol();
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

  // --- LIVE SEARCH LOGIC ---

  void _onSearchChanged(String? query) {
    final text = query ?? "";

    setState(() {
      _currentQuery = text;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Trigger search only if 3 or more characters
    if (text.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      await _performSearch(text);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final locale = Localizations.localeOf(context).languageCode;

      // The API Service is now updated to handle currency conversion internally
      final results = await ApiService.fetchProductsBySearch(
        search: query,
        locale: locale,
        page: 1,
        perPage: 10,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Live search error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void handleFullSearch(String value) {
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
    final bool isSearchingMode = _currentQuery.trim().length >= 3;

    return SafeArea(
      child: Container(
        color: isLightMode ? Colors.white : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SearchForm(
                onChanged: _onSearchChanged,
                onFieldSubmitted: (value) {
                  if (value != null) handleFullSearch(value);
                },
              ),
            ),

            Expanded(
              child: isSearchingMode
                  ? _buildLiveSearchResults()
                  : _buildHistoryAndRecent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryAndRecent() {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Wrap(
                  spacing: 8,
                  children: previousSearches.map((query) {
                    return ActionChip(
                      label: Text(query),
                      onPressed: () => handleFullSearch(query),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
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
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                  itemCount: recentlyViewedProducts.length,
                  itemBuilder: (context, index) {
                    final product = recentlyViewedProducts[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 12,
                        right: index == recentlyViewedProducts.length - 1 ? 0 : 0,
                      ),
                      child: ProductCard(
                        id: product['id'],
                        image: product['image'] ?? '',
                        category: product['category'] ?? '',
                        categoryId: product['categoryId'],
                        title: product['title'] ?? '',
                        price: (product['price'] ?? 0).toDouble(),
                        salePrice: product['salePrice'] != null
                            ? (product['salePrice'] as num).toDouble()
                            : null,
                        dicountpercent: product['discountPercent'],
                        sku: product['sku'] ?? '',
                        rating: (product['rating'] ?? 0).toDouble(),
                        discount: product['discount'],
                        freeShipping: product['freeShipping'] ?? false,
                        isNew: product['isNew'] ?? false,
                        isInStock: product['isInStock'] ?? true,
                        // ✅ Pass the manually loaded currency symbol
                        currencySymbol: _currencySymbol,
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
    );
  }

  Widget _buildLiveSearchResults() {
    if (_isLoading) {
      return GridView.count(
        padding: const EdgeInsets.all(defaultPadding),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.6,
        children: const [
          ProductCardSkelton(),
          ProductCardSkelton(),
          ProductCardSkelton(),
          ProductCardSkelton(),
        ],
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text("Sonuç bulunamadı"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: _searchResults.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.57,
      ),
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ProductCard(
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
          // ✅ Pass the manually loaded currency symbol
          currencySymbol: _currencySymbol,
          press: () {
            Navigator.pushNamed(
              context,
              productDetailsScreenRoute,
              arguments: product.id,
            );
          },
        );
      },
    );
  }
}