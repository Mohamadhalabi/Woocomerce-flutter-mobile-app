import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';

import '../search/views/global_search_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<ProductModel> products = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final int perPage = 16;
  late String locale;
  String searchQuery = "";

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchProducts();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    locale = Localizations.localeOf(context).languageCode;
    if (products.isEmpty && !isLoading) {
      fetchProducts();
    }
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
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
      final response = await ApiService.fetchProductsByCategory(
        categoryId: widget.categoryId,
        page: currentPage,
        perPage: perPage,
        locale: locale,
        search: searchQuery,
      );
      setState(() {
        products.addAll(response);
        currentPage++;
        isLoading = false;
        if (response.length < perPage) hasMore = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching category products: $e');
    }
  }

  List<Widget> buildSkeletonItems() {
    return List.generate(4, (index) {
      return Container(
        height: 130, // 👈 reduce height
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    });
  }

  void onSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalSearchScreen(query: trimmed),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // 🔍 Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: searchController,
              onSubmitted: onSearch,
              decoration: InputDecoration(
                hintText: "Ürün ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    onSearch('');
                  },
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 🔁 Product Grid with Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchProducts(isRefresh: true),
              child: products.isEmpty && isLoading
                  ? GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                padding: const EdgeInsets.all(12),
                childAspectRatio: 0.75,
                children: buildSkeletonItems(),
              )
                  : GridView.builder(
                controller: _scrollController,
                itemCount: hasMore ? products.length + 4 : products.length,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  if (index >= products.length) {
                    return buildSkeletonItems()[index % 4];
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
            ),
          ),
        ],
      ),
    );
  }
}