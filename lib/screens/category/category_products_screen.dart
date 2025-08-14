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
  /// filters: {"pa_brand": ["BMW","Audi"], "pa_buton": ["4 Buton","5 Buton"], ...}
  Map<String, List<String>> filters = {};
  /// selectedTermsByAttribute: same keys as filters but with chosen terms
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

  final List<Map<String, String>> sortOptions = const [
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

  String _prettyAttr(String key) => key.startsWith('pa_') ? key.substring(3) : key;

  /// Filter modal: one bordered dropdown per attribute, with search + checkboxes
  void openFilterModal() {
    // Create once per modal open — persists across rebuilds inside the modal
    final Map<String, List<String>> tempSelected = {
      for (final e in selectedTermsByAttribute.entries) e.key: List<String>.from(e.value),
    };
    final Map<String, TextEditingController> searchCtrls = {
      for (final k in filters.keys) k: TextEditingController(),
    };

    List<String> _filteredTerms(String attrKey) {
      final q = (searchCtrls[attrKey]?.text ?? '').trim().toLowerCase();
      final list = filters[attrKey] ?? const <String>[];
      if (q.isEmpty) return list;
      return list.where((t) => t.toLowerCase().contains(q)).toList();
    }

    void _toggleTerm(StateSetter setModalState, String attrKey, String term) {
      final list = tempSelected.putIfAbsent(attrKey, () => <String>[]);
      if (list.contains(term)) {
        list.remove(term);
      } else {
        list.add(term);
      }
      setModalState(() {});
    }

    String _selectedPreview(String attrKey) {
      final sel = tempSelected[attrKey] ?? const <String>[];
      return sel.isEmpty ? "Seçim yapılmadı" : sel.join(", ");
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close),
                      ),
                      const Text("Filtrele", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          tempSelected.clear();
                          for (final c in searchCtrls.values) c.clear();
                          setModalState(() {});
                          selectedSort = '';
                        },
                        child: const Text("Temizle"),
                      ),
                    ],
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      radius: const Radius.circular(8),
                      thickness: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---- Sort (kept as chips) ----
                            const Text("Sırala", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: sortOptions.map((sort) {
                                final isSel = selectedSort == sort['key'];
                                return ChoiceChip(
                                  label: Text(sort['label']!),
                                  selected: isSel,
                                  onSelected: (_) => setModalState(() {
                                    selectedSort = sort['key']!;
                                  }),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),
                            const Divider(height: 24),
                            const Text("Filtreler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),

                            // ---- Bordered dropdown per attribute ----
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filters.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                final attrKey = filters.keys.elementAt(i);
                                final controller = searchCtrls[attrKey]!;
                                final selected = tempSelected[attrKey] ?? <String>[];

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                                      childrenPadding: const EdgeInsets.only(
                                        bottom: 12,
                                        left: 12,
                                        right: 12,
                                      ),
                                      title: Text(
                                        _prettyAttr(attrKey),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          _selectedPreview(attrKey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (selected.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                "${selected.length}",
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.keyboard_arrow_down),
                                        ],
                                      ),
                                      children: [
                                        // Search in this attribute
                                        TextField(
                                          controller: controller,
                                          decoration: InputDecoration(
                                            hintText: "Ara...",
                                            prefixIcon: const Icon(Icons.search),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                        const SizedBox(height: 8),

                                        // Checkbox list
                                        ..._filteredTerms(attrKey).map((term) {
                                          final checked = (tempSelected[attrKey] ?? const <String>[]).contains(term);
                                          return CheckboxListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            value: checked,
                                            onChanged: (_) => _toggleTerm(setModalState, attrKey, term),
                                            title: Text(term, overflow: TextOverflow.ellipsis),
                                            controlAffinity: ListTileControlAffinity.leading,
                                          );
                                        }).toList(),

                                        // Clear this attribute only
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              tempSelected.remove(attrKey);
                                              controller.clear();
                                              setModalState(() {});
                                            },
                                            child: const Text("Bu filtreden temizle"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Apply
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Commit temp selections
                          setState(() => selectedTermsByAttribute = {
                            for (final e in tempSelected.entries) e.key: List<String>.from(e.value)
                          });
                          Navigator.pop(context);
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
            decoration: const BoxDecoration(color: primaryColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
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
                  color: Colors.white,
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
                itemCount: hasMore ? products.length + 4 : products.length,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      children: List.generate(4, (_) => const ProductCardSkelton()),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: CategoryProductsScreen.storeIndex,
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mağaza"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
