import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../../components/skleton/product/product_category_skelton.dart';
import '../../../route/route_constants.dart';
import '../../search/views/global_search_screen.dart';
// import '../../components/skleton/product/product_category_skelton.dart';
// import '../../route/route_constants.dart';
// import '../search/views/global_search_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => StoreScreenState();
}

class StoreScreenState extends State<StoreScreen> {
  List<ProductModel> products = [];
  Map<String, List<String>> filters = {};
  Map<String, List<String>> selectedTermsByAttribute = {};
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final int perPage = 16;
  String selectedSort = '';
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> sortOptions = [
    {'key': 'new_to_old', 'label': 'En Yeni'},
    {'key': 'old_to_new', 'label': 'En Eski'},
    {'key': 'price_asc', 'label': 'Fiyat: Artan'},
    {'key': 'price_desc', 'label': 'Fiyat: Azalan'},
  ];

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
    fetchFilters();
    fetchProducts();
  }

  Future<void> refresh() async {
    await fetchProducts(isRefresh: true);
  }

  Future<void> fetchFilters() async {
    try {
      final result = await ApiService.fetchFiltersForEntry(
        id: 0,
        filterType: 'all',
      );
      if (mounted) {
        setState(() => filters = result);
      }
    } catch (e) {
      debugPrint("Filter fetch error: $e");
    }
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (isLoading || (!hasMore && !isRefresh)) return;

    if (isRefresh) {
      if (mounted) {
        setState(() {
          currentPage = 1;
          hasMore = true;
          products.clear();
        });
      }
    }

    if (mounted) setState(() => isLoading = true);

    try {
      final response = await ApiService.fetchFilteredProducts(
        id: 0,
        filterType: 'all',
        page: currentPage,
        perPage: perPage,
        selectedFilters: selectedTermsByAttribute,
        sort: selectedSort,
      );

      if (mounted) {
        setState(() {
          products.addAll(response);
          currentPage++;
          isLoading = false;
          if (response.length < perPage) hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint('Error fetching store products: $e');
    }
  }

  void applyFilters() {
    fetchProducts(isRefresh: true);
  }
  void openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text('Filtrele', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        // Clear filters
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedTermsByAttribute.clear();
                              selectedSort = '';
                            });
                          },
                          child: const Text('Temizle', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 0),

                  // Body
                  Expanded(
                    child: DraggableScrollableSheet(
                      expand: true,
                      initialChildSize: 1,
                      maxChildSize: 1,
                      minChildSize: 1,
                      builder: (context, scrollController) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              const SizedBox(height: 8),
                              const Text('Sırala', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: sortOptions.map((option) {
                                  return ChoiceChip(
                                    label: Text(option['label']!),
                                    selected: selectedSort == option['key'],
                                    onSelected: (_) {
                                      setModalState(() => selectedSort = option['key']!);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              const Text('Filtreler', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...filters.entries.map((entry) {
                                final attrKey = entry.key;
                                final terms = entry.value;
                                final selected = selectedTermsByAttribute.putIfAbsent(attrKey, () => []);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(attrKey.replaceFirst("pa_", ""),
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: terms.map((term) {
                                        final isSelected = selected.contains(term);
                                        return FilterChip(
                                          label: Text(term),
                                          selected: isSelected,
                                          onSelected: (selectedState) {
                                            setModalState(() {
                                              if (selectedState) {
                                                selected.add(term);
                                              } else {
                                                selected.remove(term);
                                              }
                                              selectedTermsByAttribute[attrKey] = List<String>.from(selected);
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }).toList(),
                              const SizedBox(height: 80), // Padding for fixed button space
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Apply Button Fixed at Bottom
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        applyFilters();
                      },
                      child: const Text('Filtreyi Uygula'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        title: const Text("Tüm Ürünler"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: openFilterModal,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onSubmitted: onSearch,
              decoration: InputDecoration(
                hintText: "Ürün ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
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
                  childAspectRatio: 0.7,
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
}