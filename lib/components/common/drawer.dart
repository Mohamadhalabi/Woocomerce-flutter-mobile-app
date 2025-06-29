import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/services/api_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  static List<CategoryModel> _cachedCategories = [];
  List<CategoryModel> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locale = Localizations.localeOf(context).languageCode;
      if (_cachedCategories.isNotEmpty) {
        setState(() {
          categories = _cachedCategories;
          isLoading = false;
        });
      } else {
        fetchCategories(locale);
      }
    });
  }

  Future<void> fetchCategories(String locale) async {
    try {
      final response = await ApiService.fetchCategories(locale);
      setState(() {
        _cachedCategories = response;
        categories = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Kategori alma hatası: $e');
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
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Image.asset('assets/logo/aanahtar-logo.webp', height: 48),
          ),
          const Divider(height: 1),

          // Menu Items
          ListTile(
            leading: const Icon(Icons.home),
            title: Text("Anasayfa"),
            onTap: () => Navigator.pushNamed(context, '/'),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: Text("Mağaza"),
            onTap: () => Navigator.pushNamed(context, '/shop'),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Kategoriler'),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Sepet'),
            onTap: () => Navigator.pushNamed(context, '/cart'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Giriş / Kayıt'),
            onTap: () => Navigator.pushNamed(context, '/login'),
          ),

          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("KATEGORİLER", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Category List
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...categories.map((cat) => ListTile(
              title: Text(cat.name),
              trailing: Text('${cat.count} ürün'),
              onTap: () => Navigator.pushNamed(context, '/shop?cat=${cat.id}'),
            )),
        ],
      ),
    );
  }
}