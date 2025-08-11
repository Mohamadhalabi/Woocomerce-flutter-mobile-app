import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../components/common/app_bar.dart';
import '../../components/common/drawer.dart';
import '../../components/skleton/product/product_card_skelton.dart';
import '../../components/skleton/product/product_category_skelton.dart';
import '../../constants.dart';
import '../../entry_point.dart';
import '../../route/route_constants.dart';
import '../search/views/global_search_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final int id;
  final String title;
  final String filterType;

  const CategoryProductsScreen({
    super.key,
    required this.id,
    required this.title,
    required this.filterType,
  });

  static const int homeIndex = 0;
  static const int searchIndex = 1;
  static const int storeIndex = 2;
  static const int cartIndex = 3;
  static const int profileIndex = 4;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<ProductModel> products = [];
  Map<String, List<String>> filters = {};
  Map<String, List<String>> selectedTermsByAttribute = {};
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final int perPage = 8;
  late String locale;
  String searchQuery = "";
  String selectedSort = '';
  int currentIndex = 2;

  final ScrollController _scrollController = ScrollController();

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
      final result = await ApiService.fetchFiltersForEntry(
        id: widget.id,
        filterType: widget.filterType,
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
        id: widget.id,
        filterType: widget.filterType,
        page: currentPage,
        perPage: perPage,
        selectedFilters: selectedTermsByAttribute,
        sort: selectedSort,
      );

      setState(() {
        products.addAll(response);
        currentPage++;
        isLoading = false;
        if (response.length < perPage) hasMore = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching products: $e');
    }
  }

  void openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close),
                        ),
                        const Text("Filtrele", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedTermsByAttribute.clear();
                              selectedSort = '';
                            });
                          },
                          child: const Text("Temizle"),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      radius: const Radius.circular(8),
                      thickness: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Sırala", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: sortOptions.map((sort) {
                                return ChoiceChip(
                                  label: Text(sort['label']!),
                                  selected: selectedSort == sort['key'],
                                  onSelected: (_) => setModalState(() {
                                    selectedSort = sort['key']!;
                                  }),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 30),
                            const Text("Filtreler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...filters.entries.map((entry) {
                              final attrKey = entry.key;
                              final terms = entry.value;
                              final selected = [...(selectedTermsByAttribute[attrKey] ?? [])];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(attrKey.replaceFirst("pa_", ""),
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: terms.map((term) {
                                      final isTermSelected = selected.contains(term);
                                      return FilterChip(
                                        label: Text(term),
                                        selected: isTermSelected,
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero),
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
                                  const SizedBox(height: 12),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await fetchFilters();
                          await fetchProducts(isRefresh: true);
                        },
                        child: const Text("Filtreyi Uygula"),
                      ),
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

  void onTabChange(int index) {
    setState(() => currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/discover', (_) => false);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/cart', (_) => false);
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
        break;
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CustomDrawer(),
      appBar: CustomSearchAppBar(
        controller: TextEditingController(),
        onBellTap: () {},
        onSearchTap: () {
          setState(() => currentIndex = 1);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EntryPoint(
                onLocaleChange: (_) {},
                initialIndex: 1,
              ),
            ),
          );
        },
        onSearchSubmitted: onSearch,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: primaryColor, // ✅ primary background (works in light & dark)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white, // ✅ white back icon
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Geri',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  color: Colors.white, // ✅ white filter icon
                  onPressed: openFilterModal,
                  tooltip: 'Filtrele',
                ),
              ],
            ),
          ),
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
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.6,
                      children: List.generate(
                          4, (_) => const ProductCardSkelton()),
                    );
                  }
                  final product = products[index];
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
          currentIndex: CategoryProductsScreen.storeIndex,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EntryPoint(
                  onLocaleChange: (_) {}, // 🔹 Dummy no-op function
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
}