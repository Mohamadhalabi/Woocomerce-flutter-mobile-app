import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/product_card_skelton.dart';
import 'package:shop/constants.dart';
import 'package:shop/entry_point.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/search/views/components/search_form.dart';
import 'package:shop/services/api_service.dart';
import '../../../components/common/app_bar.dart';
import '../../../components/common/drawer.dart';

class GlobalSearchScreen extends StatefulWidget {
  final String query;

  const GlobalSearchScreen({super.key, required this.query});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  List<ProductModel> products = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final int perPage = 8;
  late String locale;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  static const int homeIndex = 0;
  static const int searchIndex = 1;
  static const int storeIndex = 2;
  static const int cartIndex = 3;
  static const int profileIndex = 4;

  @override
  void initState() {
    super.initState();
    searchController.text = widget.query;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchResults();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    locale = Localizations.localeOf(context).languageCode;
    fetchResults();
  }

  Future<void> fetchResults({bool isRefresh = false}) async {
    if (isLoading || (!hasMore && !isRefresh)) return;

    if (isRefresh) {
      setState(() {
        currentPage = 1;
        hasMore = true;
        products.clear();
      });
    }

    setState(() => isLoading = true);

    try {
      final results = await ApiService.fetchProductsBySearch(
        search: searchController.text.trim(),
        page: currentPage,
        perPage: perPage,
        locale: locale,
      );
      setState(() {
        products.addAll(results);
        currentPage++;
        isLoading = false;
        if (results.length < perPage) hasMore = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error searching products: $e");
    }
  }

  void onSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalSearchScreen(query: trimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CustomDrawer(),
      appBar: CustomSearchAppBar(
        controller: searchController,
        onBellTap: () {},
        onSearchTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EntryPoint(
                onLocaleChange: (_) {},
                initialIndex: searchIndex,
              ),
            ),
          );
        },
        onSearchSubmitted: onSearch,
      ),
      body: Column(
        children: [
          // Header bar with back button & title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: theme.iconTheme.color,
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    "Arama: ${widget.query}",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchResults(isRefresh: true),
              child: products.isEmpty && isLoading
                  ? const ProductCardSkelton()
                  : GridView.builder(
                controller: _scrollController,
                itemCount: hasMore ? products.length + 4 : products.length,
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                itemBuilder: (context, index) {
                  if (index >= products.length) {
                    return GridView.count(
                      crossAxisCount: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.6,
                      children: List.generate(
                        4,
                            (_) => const ProductCardSkelton(),
                      ),
                    );
                  }
                  final product = products[index];
                  return ProductCard(
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
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.cardColor,
          currentIndex: searchIndex,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EntryPoint(
                  onLocaleChange: (_) {},
                  initialIndex: index,
                ),
              ),
            );
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: theme.unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home), label: "Anasayfa"),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), label: "Keşfet"),
            BottomNavigationBarItem(
                icon: Icon(Icons.store), label: "Mağaza"),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
