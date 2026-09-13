// lib/screens/discover/views/discover_screen_v2.dart
//
// Search on the new API.
//
// Uses GET /products?q= rather than /search/suggest: suggest is capped at 5
// results and ignores `limit`, so it's a typeahead, not a results page. The
// products endpoint paginates properly and takes the same filters.
//
// Search matching is case-insensitive server-side — ProductController
// lowercases both sides of the title comparison because MySQL's byte-wise JSON
// collation made '%xhorse%' miss every product stored as "Xhorse".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/product/add_to_cart_modal_v2.dart';
import '../../../components/product/catalog_product_card.dart';
import '../../../components/skleton/product/product_card_skelton.dart';
import '../../../constants.dart';
import '../../../models/catalog_product.dart';
import '../../../repositories/catalog_repository.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../../services/recently_viewed_service.dart';
import '../../product/views/product_details_screen_v2.dart';

class DiscoverScreenV2 extends StatefulWidget {
  const DiscoverScreenV2({super.key});

  @override
  State<DiscoverScreenV2> createState() => DiscoverScreenV2State();
}

class DiscoverScreenV2State extends State<DiscoverScreenV2> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<ProductModel> _results = [];
  List<String> _history = [];
  List<ProductModel> _recent = [];

  Timer? _debounce;
  String _query = '';

  /// Same key the old LocalStorageService used, so existing history carries
  /// over.
  static const _historyKey = 'search_history';
  int _page = 1;
  bool _hasMore = false;
  bool _loading = false;
  bool _searched = false;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadRecent();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _search(_query, append: true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Called by EntryPoint when the tab is re-selected. Recently viewed is
  /// reloaded every time — the customer may have opened products since.
  void refresh() {
    _loadRecent();

    if (_query.isNotEmpty) {
      _search(_query);
    } else {
      _loadHistory();
    }
  }

  Future<void> _loadRecent() async {
    final recent = await RecentlyViewedService.all();
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    if (!mounted) return;
    setState(() => _history = history);
  }

  Future<void> _addHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];

    // Move to the top rather than duplicating, and cap at 10.
    list.remove(query);
    list.insert(0, query);
    if (list.length > 10) list.removeLast();

    await prefs.setStringList(_historyKey, list);
  }

  /// Removes one term, or the whole list when [query] is null.
  Future<void> _removeHistory(String? query) async {
    final prefs = await SharedPreferences.getInstance();

    if (query == null) {
      await prefs.remove(_historyKey);
      return;
    }

    final list = prefs.getStringList(_historyKey) ?? [];
    list.remove(query);
    await prefs.setStringList(_historyKey, list);
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final trimmed = value.trim();

    // The API needs 2 characters; below that, show history instead.
    if (trimmed.length < 2) {
      setState(() {
        _query = '';
        _results.clear();
        _searched = false;
        _error = null;
      });
      return;
    }

    // Debounced so typing doesn't fire a request per keystroke.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query, {bool append = false}) async {
    if (query.trim().length < 2) return;

    setState(() {
      _loading = true;
      _error = null;
      _query = query;
      if (!append) {
        _results.clear();
        _page = 1;
        _searched = true;
      }
    });

    try {
      final page = await catalogRepo.products(
        ProductQuery(
          search: query,
          page: _page,
          perPage: 20,
          sort: ProductSort.relevance,
        ),
      );

      if (!mounted) return;

      setState(() {
        _results.addAll(page.products);
        _total = page.total;
        _hasMore = page.hasMore;
        _page = page.currentPage + 1;
        _loading = false;
      });

      // Recorded only once results are back, so a typo that returns nothing
      // doesn't end up in the history list.
      if (!append && page.products.isNotEmpty) {
        await _addHistory(query);
        _loadHistory();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _submitHistory(String term) {
    _searchController.text = term;
    _searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: term.length));
    _search(term);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (v) => _search(v.trim()),
                decoration: InputDecoration(
                  hintText: 'Ürün ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _onChanged('');
                    },
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            Expanded(child: _body(theme)),
          ],
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (!_searched) return _historyView(theme);

    if (_loading && _results.isEmpty) return _skeletonGrid();

    if (_error != null && _results.isEmpty) {
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
              onPressed: () => _search(_query),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text('Sonuç bulunamadı', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '$_total sonuç',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _results.length + (_hasMore ? 2 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.60,
            ),
            itemBuilder: (context, index) {
              if (index >= _results.length) return const ProductCardSkelton();

              final product = _results[index];
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
        ),
      ],
    );
  }

  Widget _historyView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Önceki Aramalar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (_history.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _removeHistory(null);
                  _loadHistory();
                },
                child: const Text('Temizle'),
              ),
          ],
        ),
        if (_history.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              'Henüz arama yapılmadı.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._history.map(
                (term) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, size: 20),
              title: Text(term, style: const TextStyle(fontSize: 14)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () async {
                  await _removeHistory(term);
                  _loadHistory();
                },
              ),
              onTap: () => _submitHistory(term),
            ),
          ),

        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son Gezilen Ürünler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () async {
                  await RecentlyViewedService.clear();
                  _loadRecent();
                },
                child: const Text('Temizle'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 292,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recent.length,
              itemBuilder: (context, i) {
                final product = _recent[i];
                return CatalogProductCard(
                  product: product,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreenV2(slug: product.slug),
                      ),
                    );
                    // Viewing from here reorders the list.
                    _loadRecent();
                  },
                  onAddToCart: (qty) => AddToCartModalV2.show(
                    context,
                    product,
                    initialQuantity: qty,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _skeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.60,
      ),
      itemBuilder: (_, __) => const ProductCardSkelton(),
    );
  }
}