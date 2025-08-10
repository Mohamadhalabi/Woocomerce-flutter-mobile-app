import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants.dart';
import '../../../services/cart_service.dart';
import '../../../services/api_service.dart';
import 'package:shop/components/skleton/skelton.dart';
import '../../../services/alert_service.dart';
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
      isLoading = true;
    });
    loadCart();
  }

  /// Load cart with instant total + parallel product fetch
  Future<List<Map<String, dynamic>>> loadCart([List<Map<String, dynamic>>? overrideItems]) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    isLoggedIn = token != null;

    try {
      // 1) Raw items
      final items = overrideItems ??
          (isLoggedIn
              ? await CartService.fetchWooCart(token!)
              : await CartService.getGuestCart());

      // 2) Instant totals
      setState(() {
        total = _calculateTotal(items);
        cartItems = items;
      });

      // 3) Enrich for logged-in
      if (isLoggedIn && items.isNotEmpty) {
        final productIds = items
            .map((i) => int.tryParse(i['id'].toString()))
            .where((id) => id != null)
            .cast<int>()
            .toList();

        if (productIds.isNotEmpty) {
          final products = await ApiService.fetchProductsCardByIds(productIds, 'tr');
          final productMap = {for (var p in products) p.id!: p};

          for (var item in items) {
            final pid = int.tryParse(item['id'].toString());
            if (pid != null && productMap.containsKey(pid)) {
              final p = productMap[pid]!;
              item['image'] = p.image;
              item['title'] = p.title;
              item['category'] = p.category; // not shown, but kept if needed later
              item['price'] = p.salePrice ?? p.price;
              item['regular_price'] = p.salePrice != null ? p.price : null;
              item['product_id'] = p.id ?? pid;
              item['currency_symbol'] = p.currencySymbol;
            }
          }
        }
      } else {
        // Ensure guest items have product_id
        for (var item in items) {
          if (item['id'] != null) item['product_id'] = item['id'];
        }
      }

      // 4) Final state
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

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is Map<String, dynamic>) {
      // expect {raw: "..."}
      return double.tryParse(v['raw']?.toString() ?? '') ?? 0.0;
    }
    return 0.0;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final price = _asDouble(item['sale_price'] ?? item['price']);
      final rawQty = item['quantity'];
      final qty = rawQty is int
          ? rawQty
          : rawQty is Map && rawQty['value'] != null
          ? int.tryParse(rawQty['value'].toString()) ?? 1
          : int.tryParse(rawQty.toString()) ?? 1;
      return sum + (price * qty);
    });
  }

  Future<void> _changeQuantity(int index, int change) async {
    final item = cartItems[index];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final rawQty = item['quantity'];
    final currentQty = rawQty is int
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
        title: const Text('Sepetim', style: TextStyle(color: Colors.white,fontSize: 20)),
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
        child: ListView.separated(
          itemCount: cartItems.length,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          separatorBuilder: (_, __) => Divider(
            color: Theme.of(context).dividerColor.withOpacity(0.25),
            height: 1,
          ),
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

  Widget _buildQtyPill({
    required int quantity,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _roundIcon(
            icon: Icons.remove,
            onTap: quantity <= 1 ? null : onMinus,
            disabled: quantity <= 1,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13,color: primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _roundIcon(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }

  Widget _roundIcon({required IconData icon, VoidCallback? onTap, bool disabled = false}) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: disabled ? Colors.grey.shade300 : Colors.black12),
        ),
        child: Icon(icon, size: 18, color: disabled ? Colors.grey : blueColor),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> item, int index) {
    final theme = Theme.of(context);

    final currentPrice = _asDouble(item['sale_price'] ?? item['price']);
    // Try to detect a "regular" price to show strike-through + savings
    double regularPrice = _asDouble(item['regular_price']);
    if (regularPrice == 0 && item['sale_price'] != null) {
      // Some payloads keep "price" as regular when sale_price exists.
      // But earlier we overwrite item['price'] with final price for logged-in.
      // If we can find something like item['price_before_discount'], use it:
      regularPrice = _asDouble(item['price_before_discount']);
    }
    final hasDiscount = regularPrice > currentPrice && currentPrice > 0;

    final rawQty = item['quantity'];
    final quantity = rawQty is int
        ? rawQty
        : rawQty is Map && rawQty['value'] != null
        ? int.tryParse(rawQty['value'].toString()) ?? 1
        : int.tryParse(rawQty.toString()) ?? 1;

    final currency = item['currency_symbol'] ?? '₺';

    return Slidable(
      key: ValueKey(item['product_id'] ?? item['sku'] ?? index),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white,
                    child: item['image'] != null && item['image'].toString().isNotEmpty
                        ? Image.network(
                      item['image'],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    )
                        : const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title + Qty pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item['title'] ?? 'Ürün',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // (Optional) shipping info placeholder to mimic screenshot spacing
                    // Text(
                    //   'Tahmini Kargoya Teslim: 2 gün',
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    //   ),
                    // ),

                    const SizedBox(height: 8),

                    // Qty pill aligned left; price block on the right
                    Row(
                      children: [
                        _buildQtyPill(
                          quantity: quantity,
                          onMinus: () => _changeQuantity(index, -1),
                          onPlus: () => _changeQuantity(index, 1),
                        ),
                        const Spacer(),

                        // Price block (right-aligned)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                'Eklediğin Fiyat: $currency${regularPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              '$currency${(currentPrice * quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(height: 2),
                              _savingsChip(
                                currency: currency,
                                savings: (regularPrice - currentPrice) * quantity,
                              ),
                            ],
                          ],
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

  Widget _savingsChip({required String currency, required double savings}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Kazancınız: ${currency}${savings.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final currency = cartItems.isNotEmpty
        ? (cartItems.first['currency_symbol'] ?? '₺')
        : '₺';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white // ✅ White for light theme
            : Theme.of(context).cardColor, // Keep dark theme card color
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Total (collapsible look)
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white // ✅ White for light theme
                      : Theme.of(context).cardColor, // Keep dark theme card color
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Toplam',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      isLoggedIn ? '$currency${total.toStringAsFixed(2)}' : '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Checkout button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    (isLoading || total <= 0) ? Colors.grey : blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (isLoading || total <= 0 || !isLoggedIn)
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(cartItems: cartItems),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sepeti Onayla',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
