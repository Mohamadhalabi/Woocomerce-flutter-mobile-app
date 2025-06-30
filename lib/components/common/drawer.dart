import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/screens/category/category_products_screen.dart';
// import 'package:shop/screens/shop/shop_screen.dart';
import 'package:shop/services/api_service.dart';

class CustomDrawer extends StatefulWidget {
  final void Function(int)? onNavigateToIndex;
  final void Function(Widget)? onNavigateToScreen;

  const CustomDrawer({
    super.key,
    this.onNavigateToIndex,
    this.onNavigateToScreen,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  static List<dynamic>? _cachedCategories;
  List<dynamic> categories = [];
  bool isLoading = true;
  String? _locale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locale = Localizations.localeOf(context).languageCode;
      if (_cachedCategories != null) {
        categories = _cachedCategories!;
        isLoading = false;
        setState(() {});
      } else {
        fetchCategories(_locale!);
      }
    });
  }

  Future<void> fetchCategories(String locale) async {
    try {
      final response = await ApiService.fetchCategories(locale);
      setState(() {
        categories = response;
        _cachedCategories = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Image.asset('assets/logo/aanahtar-logo.webp', height: 48),
          ),
          const Divider(height: 1),

          // Navigation items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Anasayfa"),
            onTap: () => widget.onNavigateToIndex?.call(0),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text("Mağaza"),
            // onTap: () => widget.onNavigateToScreen?.call(const ShopScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Sepet'),
            onTap: () => widget.onNavigateToIndex?.call(3),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () => widget.onNavigateToIndex?.call(4),
          ),

          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("KATEGORİLER", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...categories.map(
                  (cat) => ListTile(
                title: Text(cat.name),
                trailing: Text('${cat.count} ürün'),
                    onTap: () {
                      Navigator.pop(context); // close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsScreen(
                            categoryId: cat.id,
                            categoryName: cat.name,
                          ),
                        ),
                      );
                    },
              ),
            )
        ],
      ),
    );
  }
}