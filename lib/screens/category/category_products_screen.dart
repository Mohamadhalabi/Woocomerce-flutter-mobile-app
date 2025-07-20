import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../components/skleton/product/product_category_skelton.dart';
import '../../route/route_constants.dart';
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
  Map<String, List<String>> filters = {};
  Map<String, List<String>> selectedTermsByAttribute = {}; // For multiple filters
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
      fetchFilters();
    }
  }

  Future<void> fetchFilters() async {
    try {
      final result = await ApiService.fetchFiltersForCategory(widget.categoryId);
      setState(() => filters = result);
    } catch (e) {
      debugPrint("Filter fetch error: $e");
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
      final response = await ApiService.fetchFilteredProducts(
        categoryId: widget.categoryId,
        page: currentPage,
        perPage: perPage,
        selectedFilters: selectedTermsByAttribute,
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

  void openAttributeModal(String attributeKey, List<String> terms) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final selectedTerms = [...(selectedTermsByAttribute[attributeKey] ?? [])];

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select ${attributeKey.replaceFirst("pa_", "")}"),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: terms.map((term) {
                      final isSelected = selectedTerms.contains(term);
                      return FilterChip(
                        label: Text(term),
                        selected: isSelected,
                        onSelected: (selected) {
                          setStateModal(() {
                            if (selected) {
                              selectedTerms.add(term);
                            } else {
                              selectedTerms.remove(term);
                            }
                            selectedTermsByAttribute[attributeKey] = selectedTerms.cast<String>();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      fetchProducts(isRefresh: true);
                    },
                    child: const Text("Apply Filter"),
                  )
                ],
              ),
            );
          },
        );
      },
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onSubmitted: (value) => onSearch(value),
              decoration: InputDecoration(
                hintText: "Ürün ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Filter UI
          if (filters.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: filters.entries.map((entry) {
                return ActionChip(
                  label: Text(entry.key.replaceFirst("pa_", "")),
                  onPressed: () => openAttributeModal(entry.key, entry.value),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // Active filters summary
          if (selectedTermsByAttribute.isNotEmpty)
            Wrap(
              spacing: 6,
              children: selectedTermsByAttribute.entries.expand((entry) {
                return entry.value.map((term) {
                  return Chip(
                    label: Text("${entry.key.replaceFirst("pa_", "")}: $term"),
                    onDeleted: () {
                      setState(() {
                        selectedTermsByAttribute[entry.key]?.remove(term);
                        if (selectedTermsByAttribute[entry.key]?.isEmpty ?? true) {
                          selectedTermsByAttribute.remove(entry.key);
                        }
                        fetchProducts(isRefresh: true);
                      });
                    },
                  );
                });
              }).toList(),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchProducts(isRefresh: true),
              child: products.isEmpty && isLoading
                  ? const ProductCategorySkelton()
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
                    return Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
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
    );
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
}