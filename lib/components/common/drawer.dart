// lib/components/common/drawer.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/screens/category/category_products_screen.dart';

class CustomDrawer extends StatefulWidget {
  final void Function(int)? onNavigateToIndex;
  final void Function(Widget)? onNavigateToScreen;
  final Map<String, dynamic>? initialData;

  const CustomDrawer({
    super.key,
    this.onNavigateToIndex,
    this.onNavigateToScreen,
    this.initialData,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool isCategoryExpanded = false;
  bool isBrandExpanded = false;
  bool isManufacturerExpanded = false;

  List<dynamic> categories = [];
  List<dynamic> brands = [];
  List<dynamic> manufacturers = [];

  bool loadingCategories = false;
  bool loadingBrands = false;
  bool loadingManufacturers = false;

  /* ---------- helpers ---------- */

  /// Accepts `List`, `Map`, or `null` and always returns a `List`.
  List<dynamic> _toList(dynamic v) {
    if (v == null) return <dynamic>[];
    if (v is List) return v;
    if (v is Map) return v.values.toList();
    return <dynamic>[];
  }

  /// Safe accessor for count label
  String _countText(dynamic item) {
    final c = (item is Map && item['count'] != null) ? item['count'].toString() : '0';
    return '$c ürün';
  }

  String getFilterTypeByTitle(String title) {
    if (title == "KATEGORİLER") return "category";
    if (title == "MARKALAR") return "brand";
    if (title == "ÜRETİCİ FİRMALAR") return "manufacturer";
    return "category";
  }

  @override
  void initState() {
    super.initState();

    // Try preloaded data first
    if (widget.initialData != null) {
      final d = widget.initialData!;
      categories = _toList(d['categories']);
      brands = _toList(d['brands']);
      manufacturers = _toList(d['manufacturers']);
    } else {
      // Fallback: fetch by current locale
      final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _fetchDrawerData(lang);
    }
  }

  Future<void> _fetchDrawerData(String lang) async {
    setState(() {
      loadingCategories = true;
      loadingBrands = true;
      loadingManufacturers = true;
    });

    try {
      final url = Uri.parse(
          'https://www.aanahtar.com.tr/wp-json/custom/v1/drawer-data?lang=$lang');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch drawer data (${response.statusCode})');
      }

      final jsonData = json.decode(response.body);

      setState(() {
        categories = _toList(jsonData['categories']);
        brands = _toList(jsonData['brands']);
        manufacturers = _toList(jsonData['manufacturers']);

        loadingCategories = false;
        loadingBrands = false;
        loadingManufacturers = false;
      });
    } catch (e) {
      // Fail gracefully
      setState(() {
        loadingCategories = false;
        loadingBrands = false;
        loadingManufacturers = false;
      });
      debugPrint('Drawer data error: $e');
    }
  }

  Widget buildExpansion(
      String title,
      List<dynamic> items,
      bool isLoading,
      bool isExpanded,
      ValueChanged<bool> onExpand,
      ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Container
        (
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: theme.brightness == Brightness.dark
              ? Border.all(color: Colors.white, width: 1)
              : null,
          boxShadow: [
            if (theme.brightness != Brightness.dark)
              BoxShadow(
                color: Colors.black.withOpacity(0.11),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            onExpansionChanged: onExpand,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Column(
                  children: List.generate(items.length, (index) {
                    final item = items[index] as Map<String, dynamic>;
                    return Column(
                      children: [
                        ListTile(
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 0),
                          title: Text(
                            (item['name'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          trailing: Text(
                            _countText(item),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryProductsScreen(
                                  id: item['id'],
                                  title: item['name'],
                                  filterType: getFilterTypeByTitle(title),
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          thickness: 2,
                          color: theme.dividerColor.withOpacity(0.3),
                        ),
                      ],
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Image.asset(
              'assets/logo/aanahtar-logo.webp',
              height: 48,
            ),
          ),
          Divider(height: 8, color: theme.dividerColor.withOpacity(0.3)),
          buildExpansion(
            "KATEGORİLER",
            categories,
            loadingCategories,
            isCategoryExpanded,
                (val) => setState(() => isCategoryExpanded = val),
          ),
          buildExpansion(
            "MARKALAR",
            brands,
            loadingBrands,
            isBrandExpanded,
                (val) => setState(() => isBrandExpanded = val),
          ),
          buildExpansion(
            "ÜRETİCİ FİRMALAR",
            manufacturers,
            loadingManufacturers,
            isManufacturerExpanded,
                (val) => setState(() => isManufacturerExpanded = val),
          ),
        ],
      ),
    );
  }
}
