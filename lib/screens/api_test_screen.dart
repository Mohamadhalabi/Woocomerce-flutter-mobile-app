// lib/screens/api_test_screen.dart
//
// TEMPORARY. Delete once the real screens are migrated.
//
// Proves the new Laravel API works end to end: env -> ApiClient -> repository
// -> models -> UI. Nothing else in the app imports this.
//
// To open it, temporarily change main.dart:
//     home: const SplashScreen(),
//  -> home: const ApiTestScreen(),

import 'package:flutter/material.dart';

import '../models/catalog_product.dart';
import '../repositories/catalog_repository.dart';
import '../services/api_client.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _status = 'Başlatılıyor…';
  List<ProductModel> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _status = 'Bağlanılıyor…';
    });

    try {
      final client = await ApiClient.fromEnv();
      client.setLocale(language: 'tr', currency: 'TRY');

      setState(() => _status = 'Bağlandı: ${client.baseUrl}');

      final catalog = CatalogRepository(client);
      final page = await catalog.products(
        const ProductQuery(perPage: 20, sort: ProductSort.newest),
      );

      setState(() {
        _products = page.products;
        _status = '${page.total} üründen ${page.products.length} tanesi '
            '(sayfa ${page.currentPage}/${page.lastPage})';
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _status = 'API hatası ${e.statusCode}: ${e.message}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Hata: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Testi'),
        actions: [
          IconButton(onPressed: _run, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _status.contains('hata') || _status.contains('Hata')
                ? Colors.red.shade50
                : Colors.green.shade50,
            child: Text(_status, style: const TextStyle(fontSize: 13)),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text('Ürün yok'))
                : ListView.separated(
              itemCount: _products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _products[i];

                return ListTile(
                  leading: p.thumb == null
                      ? const SizedBox(width: 48)
                      : Image.network(
                    p.thumb!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 24),
                  ),
                  title: Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    [
                      p.sku,
                      // The B2B behaviour: guests get no price at all.
                      p.priceVisible
                          ? p.formattedPrice
                          : 'Fiyat için giriş yapın',
                      if (p.badges.isNotEmpty)
                        p.badges.map((b) => b.label).join(' · '),
                    ].join('  |  '),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    p.inStock ? 'Stokta' : 'Yok',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.inStock ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}