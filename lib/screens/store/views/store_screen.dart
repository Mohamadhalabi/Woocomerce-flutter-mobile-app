import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../../components/skleton/product/product_card_skelton.dart';
import '../../../components/skleton/product/product_category_skelton.dart';
import '../../../constants.dart';
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
  // mode
  bool _onSale = false;
  int? _categoryId;

  // data
  List<ProductModel> products = [];
  Map<String, List<String>> filters = {};
  Map<String, List<String>> selectedTermsByAttribute = {};

  // paging
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  bool _hasFetchedOnce = false;
  final int perPage = 8;

  // sort
  String selectedSort = '';

  // ui
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

  /// Called the first time this tab is opened (from EntryPoint)
  void loadStoreData() {
    if (_hasFetchedOnce) return;
    fetchFilters();
    fetchProducts();
    _hasFetchedOnce = true;
  }

  /// Called by EntryPoint when tab is revisited
  void refresh() {
    fetchProducts(isRefresh: true);
  }

  /// Called by EntryPoint when switching Store mode (sale / category)
  void switchMode({required bool onSale, int? categoryId}) {
    setState(() {
      _onSale = onSale;
      _categoryId = categoryId;
      // reset state
      products.clear();
      selectedTermsByAttribute.clear();
      selectedSort = '';
      currentPage = 1;
      hasMore = true;
      _hasFetchedOnce = false;
    });
    fetchFilters();
    fetchProducts(isRefresh: true);
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

  // --- FILTER MODAL (same style as CategoryProductsScreen) ---

  String _prettyAttr(String key) => key.startsWith('pa_') ? key.substring(3) : key;

  void openFilterModal() {
    final theme = Theme.of(context);

    // temp state for the modal (persist while open)
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
      setModalState(() {}); // rebuild
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
                            // Sort
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

                            // Bordered dropdown per attribute
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
                                        bottom: 12, left: 12, right: 12,
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
                                        // Search inside this attribute
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

                                        // Options
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

                                        // Clear this attribute
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

  // --- Search routing (optional) ---
  void onSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GlobalSearchScreen(query: trimmed)),
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
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Tüm Ürünler",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0.5,
        scrolledUnderElevation: 0,
        surfaceTintColor: primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: openFilterModal),
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
                itemCount: hasMore ? products.length + 4 : products.length,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      childAspectRatio: 0.60,
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
    );
  }
}
