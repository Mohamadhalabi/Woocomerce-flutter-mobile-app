// lib/screens/store/views/store_screen_v2.dart
//
// The Mağaza tab: the whole catalogue, paginated on scroll, with the filter
// sheet from the category screen.
//
// Lives inside EntryPoint, so it has no Scaffold app bar or bottom nav of its
// own — just a header strip and the grid.
//
// Facets are NOT fetched on open. /filters runs a query per filterable
// attribute plus two joins across the catalogue; it's only needed once someone
// taps the filter icon.

import 'package:flutter/material.dart';

import '../../../components/product/add_to_cart_modal_v2.dart';
import '../../../components/product/catalog_product_card.dart';
import '../../../components/skleton/product/product_card_skelton.dart';
import '../../../components/skleton/product/product_category_skelton.dart';
import '../../../constants.dart';
import '../../../models/catalog_product.dart';
import '../../../models/filter_models.dart';
import '../../../repositories/catalog_repository.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../../services/currency_service.dart';
import '../../product/views/product_details_screen_v2.dart';

class StoreScreenV2 extends StatefulWidget {
  const StoreScreenV2({super.key});

  @override
  State<StoreScreenV2> createState() => StoreScreenV2State();
}

class StoreScreenV2State extends State<StoreScreenV2>
    with AutomaticKeepAliveClientMixin {
  ProductQuery _query = const ProductQuery(perPage: 20);

  final List<ProductModel> _products = [];
  FilterFacets _facets = FilterFacets.empty;

  bool _loading = false;
  bool _loadingFacets = false;
  bool _firstLoad = true;
  bool _hasMore = true;
  int _total = 0;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  static const _sortOptions = <MapEntry<String, ProductSort>>[
    MapEntry('Varsayılan', ProductSort.manual),
    MapEntry('En Yeni', ProductSort.newest),
    MapEntry('Fiyat: Artan', ProductSort.priceAsc),
    MapEntry('Fiyat: Azalan', ProductSort.priceDesc),
    MapEntry('İsme Göre', ProductSort.name),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadStoreData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 400 &&
          !_loading &&
          _hasMore) {
        _loadProducts();
      }
    });

    // Kept alive inside an IndexedStack, so a currency switch elsewhere never
    // rebuilds this on its own.
    CurrencyService.revision.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    CurrencyService.revision.removeListener(_onCurrencyChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) _loadProducts(reset: true);
  }

  /// Called by EntryPoint when the tab is first opened.
  void loadStoreData() => _loadProducts(reset: true);

  void refresh() => _loadProducts(reset: true);

  /// Switches the tab into a filtered mode — used by the home screen's
  /// "Tümünü Gör" links.
  void switchMode({bool onSale = false, String? categorySlug}) {
    setState(() {
      _query = ProductQuery(
        perPage: 20,
        onSale: onSale,
        category: categorySlug,
      );
      _facets = FilterFacets.empty;
    });
    _loadProducts(reset: true);
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;

    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _products.clear();
        _hasMore = true;
        _firstLoad = true;
        _query = _query.copyWith(page: 1);
      }
    });

    try {
      final page = await catalogRepo.products(_query);
      if (!mounted) return;

      setState(() {
        _products.addAll(page.products);
        _total = page.total;
        _hasMore = page.hasMore;
        _query = _query.copyWith(page: page.currentPage + 1);
        _loading = false;
        _firstLoad = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _firstLoad = false;
      });
    }
  }

  Future<void> _loadFacets() async {
    if (_loadingFacets) return;

    setState(() => _loadingFacets = true);
    try {
      final facets = await catalogRepo.filters(_query);
      if (!mounted) return;
      setState(() {
        _facets = facets;
        _loadingFacets = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingFacets = false);
    }
  }

  Future<void> _onFilterTap() async {
    if (_facets.isEmpty) {
      await _loadFacets();
    } else {
      _loadFacets();
    }

    if (!mounted) return;
    _openFilterModal();
  }

  Future<void> _applyQuery(ProductQuery next) async {
    setState(() => _query = next.copyWith(page: 1));
    await _loadProducts(reset: true);
    _loadFacets();
  }

  int get _activeFilterCount =>
      _query.attributeValueIds.length +
          _query.brands.length +
          _query.manufacturers.length +
          (_query.onSale ? 1 : 0) +
          (_query.inStock ? 1 : 0);

  void _openFilterModal() {
    var tempAttrs = List<int>.from(_query.attributeValueIds);
    var tempBrands = List<String>.from(_query.brands);
    var tempMakers = List<String>.from(_query.manufacturers);
    var tempSort = _query.sort ?? ProductSort.manual;
    var tempInStock = _query.inStock;
    var tempOnSale = _query.onSale;

    final searchCtrls = <int, TextEditingController>{
      for (final a in _facets.attributes) a.id: TextEditingController(),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<AttributeValueFacet> visibleValues(AttributeFacet attr) {
              final q = (searchCtrls[attr.id]?.text ?? '').trim().toLowerCase();
              if (q.isEmpty) return attr.values;
              return attr.values
                  .where((v) => v.name.toLowerCase().contains(q))
                  .toList();
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close),
                        ),
                        const Text(
                          "Filtrele",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => setModalState(() {
                            tempAttrs.clear();
                            tempBrands.clear();
                            tempMakers.clear();
                            tempInStock = false;
                            tempOnSale = false;
                            tempSort = ProductSort.manual;
                            for (final c in searchCtrls.values) {
                              c.clear();
                            }
                          }),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sırala",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _sortOptions.map((option) {
                                  return ChoiceChip(
                                    label: Text(option.key),
                                    selected: tempSort == option.value,
                                    onSelected: (_) => setModalState(
                                            () => tempSort = option.value),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                ListTileControlAffinity.leading,
                                value: tempInStock,
                                onChanged: (v) => setModalState(
                                        () => tempInStock = v ?? false),
                                title: const Text("Sadece stokta olanlar"),
                              ),
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                ListTileControlAffinity.leading,
                                value: tempOnSale,
                                onChanged: (v) =>
                                    setModalState(() => tempOnSale = v ?? false),
                                title: const Text("Sadece indirimdekiler"),
                              ),
                              const Divider(height: 24),

                              if (_facets.brands.isNotEmpty) ...[
                                _facetGroup(
                                  title: "Marka",
                                  setModalState: setModalState,
                                  options: _facets.brands,
                                  selected: tempBrands,
                                ),
                                const SizedBox(height: 6),
                              ],

                              if (_facets.manufacturers.isNotEmpty) ...[
                                _facetGroup(
                                  title: "Üretici",
                                  setModalState: setModalState,
                                  options: _facets.manufacturers,
                                  selected: tempMakers,
                                ),
                                const SizedBox(height: 6),
                              ],

                              // Values within one attribute are OR'd; different
                              // attributes are AND'd — which is why counts stay
                              // non-zero when a second value in the same group
                              // is ticked.
                              ..._facets.attributes.map((attr) {
                                final selectedCount = attr.values
                                    .where((v) => tempAttrs.contains(v.id))
                                    .length;

                                return Container(
                                  decoration: BoxDecoration(
                                    border:
                                    Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin:
                                  const EdgeInsets.symmetric(vertical: 3),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      childrenPadding: const EdgeInsets.only(
                                          bottom: 12, left: 12, right: 12),
                                      title: Text(
                                        attr.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (selectedCount > 0)
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue
                                                    .withOpacity(.12),
                                                borderRadius:
                                                BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                "$selectedCount",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                    FontWeight.w600),
                                              ),
                                            ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.keyboard_arrow_down),
                                        ],
                                      ),
                                      children: [
                                        if (attr.values.length > 8)
                                          TextField(
                                            controller: searchCtrls[attr.id],
                                            decoration: InputDecoration(
                                              hintText: "Ara...",
                                              prefixIcon:
                                              const Icon(Icons.search),
                                              contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(10),
                                              ),
                                            ),
                                            onChanged: (_) =>
                                                setModalState(() {}),
                                          ),
                                        ...visibleValues(attr).map((value) {
                                          return CheckboxListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity:
                                            ListTileControlAffinity.leading,
                                            value: tempAttrs.contains(value.id),
                                            onChanged: (_) =>
                                                setModalState(() {
                                                  tempAttrs.contains(value.id)
                                                      ? tempAttrs.remove(value.id)
                                                      : tempAttrs.add(value.id);
                                                }),
                                            title: Text(
                                              "${value.name} (${value.count})",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              }),
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
                          onPressed: () {
                            Navigator.pop(context);
                            _applyQuery(_query.copyWith(
                              attributeValueIds: tempAttrs,
                              brands: tempBrands,
                              manufacturers: tempMakers,
                              sort: tempSort,
                              inStock: tempInStock,
                              onSale: tempOnSale,
                            ));
                          },
                          child: const Text("Filtreyi Uygula"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _facetGroup({
    required String title,
    required StateSetter setModalState,
    required List<TermFacet> options,
    required List<String> selected,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding:
          const EdgeInsets.only(bottom: 12, left: 12, right: 12),
          title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "${selected.length}",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
          children: options.map((option) {
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: selected.contains(option.slug),
              onChanged: (_) => setModalState(() {
                selected.contains(option.slug)
                    ? selected.remove(option.slug)
                    : selected.add(option.slug);
              }),
              title: Text(
                "${option.name} (${option.count})",
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(color: primaryColor),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tüm Ürünler',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (_total > 0)
                        Text(
                          '$_total ürün',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: _loadingFacets && _facets.isEmpty
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.filter_alt_outlined),
                      color: Colors.white,
                      onPressed: _loadingFacets ? null : _onFilterTap,
                      tooltip: 'Filtrele',
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "$_activeFilterCount",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_firstLoad && _loading) return const ProductCategorySkelton();

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Colors.grey),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadProducts(reset: true),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(child: Text('Ürün bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(reset: true),
      child: GridView.builder(
        controller: _scrollController,
        // Two extra cells while more pages exist: the skeletons ARE the
        // loading indicator, so the grid never jumps.
        itemCount: _hasMore ? _products.length + 2 : _products.length,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.60,
        ),
        itemBuilder: (context, index) {
          if (index >= _products.length) return const ProductCardSkelton();

          final product = _products[index];
          return CatalogProductCard(
            product: product,
            width: double.infinity,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreenV2(slug: product.slug),
              ),
            ),
            onAddToCart: (qty) => AddToCartModalV2.show(
              context,
              product,
              initialQuantity: qty,
            ),
          );
        },
      ),
    );
  }
}