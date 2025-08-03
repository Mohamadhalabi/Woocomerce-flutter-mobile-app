import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../../components/skleton/product/product_card_skelton.dart';
import '../../../components/skleton/product/product_category_skelton.dart';
import '../../../route/route_constants.dart';
import '../../search/views/global_search_screen.dart';

class StoreScreen extends StatefulWidget {
  final bool onSale;
  final int? categoryId;

  const StoreScreen({super.key, this.onSale = false, this.categoryId});

  @override
  State<StoreScreen> createState() => StoreScreenState();
}

class StoreScreenState extends State<StoreScreen> {
  bool _onSale = false;
  int? _categoryId;
  List<ProductModel> products = [];
  Map<String, List<String>> filters = {};
  Map<String, List<String>> selectedTermsByAttribute = {};
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  bool _hasFetchedOnce = false;
  final int perPage = 8;
  String selectedSort = '';
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
    _onSale = widget.onSale;
    _categoryId = widget.categoryId;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchProducts();
      }
    });
  }

  void loadStoreData() {
    if (_hasFetchedOnce) return;
    fetchFilters();
    fetchProducts();
    _hasFetchedOnce = true;
  }

  void switchMode({required bool onSale, int? categoryId}) {
    setState(() {
      _onSale = onSale;
      _categoryId = categoryId;
      _hasFetchedOnce = false;
      products.clear();
      currentPage = 1;
      hasMore = true;
    });
    fetchFilters();
    fetchProducts(isRefresh: true);
  }

  Future<void> refresh() async {
    await fetchProducts(isRefresh: true);
  }

  Future<void> fetchFilters() async {
    try {
      final result = await ApiService.fetchFiltersForEntry(
        id: _categoryId ?? 0,
        filterType: _categoryId != null ? 'category' : 'all',
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
      setState(() {
        currentPage = 1;
        hasMore = true;
        products.clear();
      });
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.fetchFilteredProducts(
        id: _categoryId ?? 0,
        filterType: _categoryId != null ? 'category' : 'all',
        page: currentPage,
        perPage: perPage,
        selectedFilters: selectedTermsByAttribute,
        sort: selectedSort,
        onSale: _onSale,
      );

      setState(() {
        products.addAll(response);
        currentPage++;
        isLoading = false;
        if (response.length < perPage) hasMore = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching store products: $e');
    }
  }

  void applyFilters() {
    fetchProducts(isRefresh: true);
  }

  void openFilterModal() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close,
                              color: theme.iconTheme.color),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Filtrele',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedTermsByAttribute.clear();
                              selectedSort = '';
                            });
                          },
                          child: Text('Temizle',
                              style: TextStyle(color: theme.colorScheme.primary)),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0, color: theme.dividerColor),
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
                              Text('Sırala',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: sortOptions.map((option) {
                                  return ChoiceChip(
                                    label: Text(option['label']!,
                                        style: theme.textTheme.bodyMedium),
                                    selected: selectedSort == option['key'],
                                    onSelected: (_) {
                                      setModalState(
                                              () => selectedSort = option['key']!);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              Text('Filtreler',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...filters.entries.map((entry) {
                                final attrKey = entry.key;
                                final terms = entry.value;
                                final selected = selectedTermsByAttribute
                                    .putIfAbsent(attrKey, () => []);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(attrKey.replaceFirst("pa_", ""),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: terms.map((term) {
                                        final isSelected =
                                        selected.contains(term);
                                        return FilterChip(
                                          label: Text(term,
                                              style: theme.textTheme.bodyMedium),
                                          selected: isSelected,
                                          onSelected: (selectedState) {
                                            setModalState(() {
                                              if (selectedState) {
                                                selected.add(term);
                                              } else {
                                                selected.remove(term);
                                              }
                                              selectedTermsByAttribute[
                                              attrKey] =
                                              List<String>.from(selected);
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }).toList(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: theme.cardColor,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Tüm Ürünler"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        foregroundColor: theme.appBarTheme.foregroundColor ??
            theme.colorScheme.onSurface,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        surfaceTintColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: openFilterModal,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchProducts(isRefresh: true),
              child: products.isEmpty && isLoading
                  ? const ProductCategorySkelton()
                  : GridView.builder(
                controller: _scrollController,
                itemCount:
                hasMore ? products.length + 4 : products.length,
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.60,
                ),
                itemBuilder: (context, index) {
                  if (index >= products.length) {
                    return GridView.count(
                      crossAxisCount: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.60,
                      children: List.generate(
                          4, (_) => const ProductCardSkelton()),
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