import 'package:flutter/material.dart';
import 'package:shop/screens/category/category_products_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  bool _drawerDataFetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      categories = (widget.initialData!['categories'] as Map<String, dynamic>).values.toList();
      brands = widget.initialData!['brands'] ?? [];
      manufacturers = widget.initialData!['manufacturers'] ?? [];
      _drawerDataFetched = true;
    } else {
      final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      fetchDrawerData(lang); // Fallback fetch
      _drawerDataFetched = true;
    }
  }

  String getFilterTypeByTitle(String title) {
    if (title == "KATEGORİLER") return "category";
    if (title == "MARKALAR") return "brand";
    if (title == "ÜRETİCİ FİRMALAR") return "manufacturer";
    return "category";
  }

  Future<void> fetchDrawerData(String lang) async {
    final url = Uri.parse('https://www.aanahtar.com.tr/wp-json/custom/v1/drawer-data?lang=$lang');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      setState(() {
        categories = (jsonData['categories'] as Map<String, dynamic>).values.toList();
        brands = jsonData['brands'] ?? [];
        manufacturers = jsonData['manufacturers'] ?? [];

        loadingCategories = false;
        loadingBrands = false;
        loadingManufacturers = false;
      });
    } else {
      throw Exception('Failed to fetch drawer data');
    }
  }

  Widget buildExpansion(
      String title,
      List<dynamic> items,
      bool isLoading,
      bool isExpanded,
      Function(bool) onExpand,
      ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor, // ✅ Theme-aware background
          borderRadius: BorderRadius.circular(10),
          border: theme.brightness == Brightness.dark
              ? Border.all(color: Colors.white, width: 1) // ✅ White border in dark mode
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
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), // ✅ Theme-aware text
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
                    final item = items[index];
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                          title: Text(
                            item['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color, // ✅ Theme-aware
                            ),
                          ),
                          trailing: Text(
                            '${item['count']} ürün',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), // ✅ Theme-aware
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
                          color: theme.dividerColor.withOpacity(0.3), // ✅ Theme-aware
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
          Divider(
            height: 8,
            color: theme.dividerColor.withOpacity(0.3), // ✅ Theme-aware
          ),
          buildExpansion(
              "KATEGORİLER",
              categories,
              loadingCategories,
              isCategoryExpanded,
                  (val) => setState(() => isCategoryExpanded = val)
          ),
          buildExpansion(
              "MARKALAR",
              brands,
              loadingBrands,
              isBrandExpanded,
                  (val) => setState(() => isBrandExpanded = val)
          ),
          buildExpansion(
              "ÜRETİCİ FİRMALAR",
              manufacturers,
              loadingManufacturers,
              isManufacturerExpanded,
                  (val) => setState(() => isManufacturerExpanded = val)
          ),
        ],
      ),
    );
  }
}