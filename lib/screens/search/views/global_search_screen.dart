import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../../components/common/drawer.dart';
import '../../../components/common/main_scaffold.dart';

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
  final int perPage = 16;
  late String locale;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

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

  Future<void> fetchResults() async {
    if (isLoading || !hasMore) return;

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

  void handleNewSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == widget.query) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalSearchScreen(query: trimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      searchController: searchController,
      currentIndex: 1,
      onTabChange: (index) {
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      drawer: CustomDrawer(
        onNavigateToIndex: (index) {
          // Optional: handle bottom nav index change
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onNavigateToScreen: (screen) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
      body: products.isEmpty && isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: products.length + (hasMore ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const Center(child: CircularProgressIndicator());
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
                '/product-detail',
                arguments: product.id,
              );
            },
          );
        },
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