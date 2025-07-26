import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants.dart';
import '../../../services/cart_service.dart';
import '../../../services/api_service.dart';
import 'package:shop/components/skleton/skelton.dart';
import '../../../services/alert_service.dart';
import 'dart:async';

import '../../route/route_constants.dart';


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  double total = 0;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    loadCart();
  }
  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> loadCart([List<Map<String, dynamic>>? overrideItems]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    isLoggedIn = token != null;

    try {
      final items = overrideItems ??
          (isLoggedIn
              ? await CartService.fetchWooCart(token!)
              : await CartService.getGuestCart());

      if (isLoggedIn) {
        for (var item in items) {
          final productId = int.tryParse(item['id'].toString());
          if (productId != null) {
            final product = await ApiService.fetchProductById(productId, 'tr');
            item['image'] = product.image;
            item['title'] = product.title;
            item['category'] = product.category;
            item['price'] = product.salePrice ?? product.price;
            item['product_id'] = product.id;
            item['key'] = item['key'];
            item['currency_symbol'] = product.currencySymbol;
          }
        }
      }

      setState(() {
        cartItems = items;
        total = _calculateTotal(items);
        isLoading = false;
      });

      return items;
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return [];
      AlertService.showTopAlert(
        context,
        "Sepet yüklenemedi: ${e.toString()}",
        isError: true,
      );
      return [];
    }
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final rawPrice = item['sale_price'] ?? item['price'];
      double price = 0.0;

      if (rawPrice is Map<String, dynamic>) {
        price = double.tryParse(rawPrice['raw'].toString()) ?? 0.0;
      } else if (rawPrice is num) {
        price = rawPrice.toDouble();
      } else if (rawPrice is String) {
        price = double.tryParse(rawPrice) ?? 0.0;
      }

      final rawQty = item['quantity'];
      final quantity = rawQty is int
          ? rawQty
          : rawQty is Map && rawQty['value'] != null
          ? int.tryParse(rawQty['value'].toString()) ?? 1
          : int.tryParse(rawQty.toString()) ?? 1;

      return sum + (price * quantity);
    });
  }

  Future<void> _changeQuantity(int index, int change) async {
    final item = cartItems[index];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final rawQty = item['quantity'];
    int currentQty = rawQty is int
        ? rawQty
        : rawQty is Map && rawQty['value'] != null
        ? int.tryParse(rawQty['value'].toString()) ?? 1
        : int.tryParse(rawQty.toString()) ?? 1;

    final newQty = currentQty + change;
    if (newQty < 1) {
      await _removeItem(index);
      return;
    }

    // 🟢 Optimistically update UI first
    setState(() {
      cartItems[index]['quantity'] = newQty;
      total = _calculateTotal(cartItems);
    });

    final cartItemKey = item['key']?.toString();

    if (token != null && cartItemKey != null) {
      // 🔁 Update server in background
      try {
        await CartService.setWooCartQuantity(
          token,
          cartItemKey,
          newQty,
          productId: item['product_id'] ?? item['id'],
        );

        // Optional: sync again in background if needed later
        // final updated = await CartService.fetchWooCart(token);
        // await loadCart(updated);
      } catch (e) {
        if (!mounted) return;

        // 🔴 If update failed, revert change and show error
        setState(() {
          cartItems[index]['quantity'] = currentQty;
          total = _calculateTotal(cartItems);
        });

        AlertService.showTopAlert(
          context,
          'Miktar güncellenemedi: ${e.toString()}',
          isError: true,
        );
      }
    } else {
      // 👤 Guest cart (local)
      await CartService.saveGuestCartList(cartItems);
    }
  }

  Future<void> _removeItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final item = cartItems[index];

    final cartItemKey = item['key']?.toString();

    if (token != null && cartItemKey != null) {
      try {
        await CartService.removeWooCartItem(token, cartItemKey);
      } catch (e) {
        if (!mounted) return;

        AlertService.showTopAlert(
          context,
          'Ürün silinirken hata oluştu: ${e.toString()}',
          isError: true,
        );
      }
    } else {
      cartItems.removeAt(index);
      await CartService.saveGuestCartList(cartItems);
    }

    await loadCart();
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      isLoading = true;
    });

    if (token != null) {
      await CartService.clearWooCart(token);
    } else {
      await CartService.clearGuestCart();
    }

    await loadCart();

    if (!mounted) return;

    AlertService.showTopAlert(
      context,
      'Sepet başarıyla temizlendi',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Sepetim', style: TextStyle(color: Colors.white)),
        backgroundColor: blueColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: clearCart,
          ),
        ],
      ),
      body: isLoading
          ? ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Skeleton(width: 100, height: 100, radious: 8),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: double.infinity, height: 14),
                      SizedBox(height: 8),
                      Skeleton(width: 120, height: 14),
                      SizedBox(height: 8),
                      Skeleton(width: 80, height: 14),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      )
          : cartItems.isEmpty
          ? const Center(child: Text('Sepetiniz boş'))
          : RefreshIndicator(
        onRefresh: () async => await loadCart(),
        child: ListView.builder(
          itemCount: cartItems.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final item = cartItems[index];

            final priceRaw = item['sale_price'] ?? item['price'];
            double price = 0.0;

            if (priceRaw is Map<String, dynamic>) {
              price = double.tryParse(priceRaw['raw'].toString()) ?? 0.0;
            } else if (priceRaw is num) {
              price = priceRaw.toDouble();
            } else if (priceRaw is String) {
              price = double.tryParse(priceRaw) ?? 0.0;
            }


            final rawQty = item['quantity'];
            final quantity = rawQty is int
                ? rawQty
                : rawQty is Map && rawQty['value'] != null
                ? int.tryParse(rawQty['value'].toString()) ?? 1
                : int.tryParse(rawQty.toString()) ?? 1;

// -- Snippet inside ListView.builder itemBuilder --

            return Slidable(
              key: ValueKey(item['product_id'] ?? item['sku']),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (_) => _removeItem(index),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Sil',
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    GestureDetector(
                    onTap: () {
              Navigator.pushNamed(
              context,
              productDetailsScreenRoute,
              arguments: item['product_id'] ?? item['id'],
              );
              },
                child: Container(
                  margin: const EdgeInsets.only(top: 15, left: 3),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item['image'] != null && item['image'].toString().isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['image'],
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                    ),
                  )
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      productDetailsScreenRoute,
                      arguments: item['product_id'] ?? item['id'],
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Ürün',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['category'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                          Text(
                            '${item['currency_symbol'] ?? '₺'}${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: blueColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey, width: 1.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: blueColor),
                                      onPressed: () => _changeQuantity(index, -1),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      height: 25,
                                      child: TextField(
                                        controller: TextEditingController(text: quantity.toString()),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: blueColor,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (val) {
                                          if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();

                                          debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                                            final newQty = int.tryParse(val) ?? quantity;
                                            if (newQty > 0 && newQty != quantity) {
                                              final diff = newQty - quantity;
                                              await _changeQuantity(index, diff);
                                            }
                                          });
                                        },
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.add, color: blueColor),
                                      onPressed: () => _changeQuantity(index, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (isLoggedIn)
                                Text(
                                  '₺${(price * quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Toplam:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              isLoggedIn
                  ? '${cartItems.isNotEmpty ? (cartItems.first['currency_symbol'] ?? '₺') : '₺'}${total.toStringAsFixed(2)}'
                  : '-',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}