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
import '../checkout/views/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  double total = 0;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    loadCart();
    CartService.onGuestCartUpdated = () {
      loadCart();
    };
  }

  @override
  void dispose() {
    CartService.onGuestCartUpdated = null;
    debounceTimer?.cancel();
    super.dispose();
  }

  void refreshWithSkeleton() {
    setState(() {
      isLoading = true; // triggers skeleton
    });
    loadCart();
  }
  /// Load cart with instant total + parallel product fetch
  Future<List<Map<String, dynamic>>> loadCart([List<Map<String, dynamic>>? overrideItems]) async {
    setState(() {
      isLoading = true; // ✅ Show skeleton while loading
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    isLoggedIn = token != null;

    try {
      // 1️⃣ Get raw cart items (Woo or Guest)
      final items = overrideItems ??
          (isLoggedIn
              ? await CartService.fetchWooCart(token!)
              : await CartService.getGuestCart());

      // 2️⃣ Instant total update (before product details fetch)
      setState(() {
        total = _calculateTotal(items);
        cartItems = items;
      });

      // 3️⃣ Fetch product details in batch for logged-in users
      if (isLoggedIn && items.isNotEmpty) {
        final productIds = items
            .map((item) => int.tryParse(item['id'].toString()))
            .where((id) => id != null)
            .cast<int>()
            .toList();

        if (productIds.isNotEmpty) {
          final products = await ApiService.fetchProductsCardByIds(productIds, 'tr');
          final productMap = {for (var p in products) p.id!: p};

          for (var item in items) {
            final pid = int.tryParse(item['id'].toString());
            if (pid != null && productMap.containsKey(pid)) {
              final product = productMap[pid]!;
              item['image'] = product.image;
              item['title'] = product.title;
              item['category'] = product.category;
              item['price'] = product.salePrice ?? product.price;
              item['product_id'] = product.id ?? pid;
              item['currency_symbol'] = product.currencySymbol;
            }
          }
        }
      } else {
        // ✅ Ensure guest cart has product_id set
        for (var item in items) {
          if (item['id'] != null) {
            item['product_id'] = item['id'];
          }
        }
      }

      // 4️⃣ Final state update with full details
      setState(() {
        cartItems = items;
        total = _calculateTotal(items); // recalc after details fetched
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

    setState(() {
      cartItems[index]['quantity'] = newQty;
      total = _calculateTotal(cartItems);
    });

    final cartItemKey = item['key']?.toString();

    if (token != null && cartItemKey != null) {
      try {
        await CartService.setWooCartQuantity(
          token,
          cartItemKey,
          newQty,
          productId: item['product_id'] ?? item['id'],
        );
      } catch (e) {
        if (!mounted) return;
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
          ? _buildSkeleton()
          : cartItems.isEmpty
          ? const Center(child: Text('Sepetiniz boş'))
          : RefreshIndicator(
        onRefresh: () async => await loadCart(),
        child: ListView.builder(
          itemCount: cartItems.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final item = cartItems[index];
            return _buildCartItem(context, item, index);
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
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
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> item, int index) {
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
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            productDetailsScreenRoute,
            arguments: item['product_id'] ?? item['id'],
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: Colors.white24, width: 1)
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.19), // soft shadow
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.grey.shade400,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item['image'] != null &&
                    item['image'].toString().isNotEmpty
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

              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item['title'] ?? 'Ürün',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Category
                    Text(
                      item['category'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price
                    if (isLoggedIn)
                      Text(
                        '${item['currency_symbol'] ?? '₺'}${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: blueColor,
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    const SizedBox(height: 12),

                    // Quantity Controls
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
                                icon: Icon(
                                  Icons.remove,
                                  color: quantity <= 1
                                      ? Colors.grey
                                      : blueColor,
                                ),
                                onPressed: quantity <= 1
                                    ? null
                                    : () => _changeQuantity(index, -1),
                              ),
                              SizedBox(
                                width: 40,
                                height: 25,
                                child: TextField(
                                  controller: TextEditingController(
                                      text: quantity.toString()),
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
                                    if (debounceTimer?.isActive ?? false) {
                                      debounceTimer!.cancel();
                                    }
                                    debounceTimer = Timer(
                                      const Duration(milliseconds: 500),
                                          () async {
                                        final newQty =
                                            int.tryParse(val) ?? quantity;
                                        if (newQty > 0 && newQty != quantity) {
                                          final diff = newQty - quantity;
                                          await _changeQuantity(index, diff);
                                        }
                                      },
                                    );
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
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🏷 Total
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
          if (isLoggedIn)
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isLoading || total <= 0)
                      ? Colors.grey // Disabled color
                      : blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (isLoading || total <= 0)
                    ? null // ❌ Disabled
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(cartItems: cartItems),
                    ),
                  );
                },
                child: const Text(
                  "Ödeme sayfasına git",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    );
  }
}