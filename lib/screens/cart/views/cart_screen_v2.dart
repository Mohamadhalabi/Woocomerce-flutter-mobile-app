// lib/screens/cart/views/cart_screen_v2.dart
//
// The cart on the new API, in the original screen's style.
//
// Three things differ from the WooCommerce version:
//   1. Line items are addressed by an INTEGER item id (CartItem.id) — not the
//      string key Woo used, and not the product id.
//   2. Guests get a real server-side cart via the X-Cart-Token header, so
//      there's no local guest cart to merge here.
//   3. Prices are null for guests and unapproved accounts.
//
// Every mutation returns the whole cart, so nothing needs refetching after one.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shop/components/skleton/skelton.dart';

import '../../../constants.dart';
import '../../../repositories/cart_repository.dart';
import '../../../services/alert_service.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../checkout/views/checkout_screen_v2.dart';
import '../../product/views/product_details_screen_v2.dart';

class CartScreenV2 extends StatefulWidget {
  const CartScreenV2({super.key});

  @override
  State<CartScreenV2> createState() => CartScreenV2State();
}

class CartScreenV2State extends State<CartScreenV2> {
  Cart _cart = Cart.empty;

  bool isLoading = true;
  String? _error;

  /// Item ids currently updating, so only that row shows a spinner.
  final Set<int> _busyItems = {};

  /// One controller and focus node per line, keyed by cart item id.
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, FocusNode> _qtyFocus = {};

  bool get isLoggedIn => authRepo.isSignedIn;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final f in _qtyFocus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void refreshWithSkeleton() {
    setState(() => isLoading = true);
    loadCart();
  }

  Future<void> loadCart() async {
    setState(() => _error = null);

    try {
      // Returns an empty cart when no token is stored rather than asking the
      // server — otherwise every visit would create an orphan cart row.
      final cart = await cartRepo.fetch();

      if (!mounted) return;
      setState(() {
        _cart = cart;
        isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        isLoading = false;
      });
      AlertService.showTopAlert(
        context,
        'Sepet yüklenemedi: ${e.message}',
        isError: true,
      );
    }
  }

  Future<void> _changeQuantity(CartItem item, int change) async {
    final next = item.quantity + change;

    if (next < 1) {
      await _removeItem(item);
      return;
    }

    setState(() => _busyItems.add(item.id));

    try {
      final cart = await cartRepo.updateQuantity(item.id, next);
      if (!mounted) return;
      setState(() => _cart = cart);
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(
        context,
        'Miktar güncellenemedi: ${e.message}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busyItems.remove(item.id));
    }
  }

  Future<void> _removeItem(CartItem item) async {
    setState(() => _busyItems.add(item.id));

    try {
      final cart = await cartRepo.remove(item.id);
      if (!mounted) return;
      setState(() => _cart = cart);
    } on ApiException catch (e) {
      if (!mounted) return;
      AlertService.showTopAlert(
        context,
        'Ürün silinirken hata oluştu: ${e.message}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busyItems.remove(item.id));
    }
  }

  /// There's no bulk-clear endpoint, so this deletes line by line. Each call
  /// returns the updated cart, and the last one is the source of truth.
  Future<void> clearCart() async {
    if (_cart.isEmpty) return;

    final previous = _cart;
    setState(() {
      _cart = Cart.empty;
      isLoading = false;
    });

    try {
      Cart latest = previous;
      for (final item in previous.items) {
        latest = await cartRepo.remove(item.id);
      }

      if (!mounted) return;
      setState(() => _cart = latest);
      AlertService.showTopAlert(context, 'Sepet başarıyla temizlendi',
          isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cart = previous);
      AlertService.showTopAlert(
        context,
        'Sepet temizlenemedi: ${e.message}',
        isError: true,
      );
    }
  }

  Future<void> _checkout() async {
    final ordered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreenV2(cart: _cart)),
    );

    // The server empties the cart once the order commits, so refetch either
    // way — an abandoned checkout may still have changed quantities.
    if (mounted) loadCart();
    if (ordered == true && mounted) {
      setState(() => _cart = Cart.empty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sepetim',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _cart.isEmpty ? null : clearCart,
          ),
        ],
      ),
      body: isLoading
          ? _buildSkeleton()
          : _cart.isEmpty
          ? Center(
        child: Text(
          _error ?? 'Sepetiniz boş',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadCart,
        child: ListView.separated(
          itemCount: _cart.items.length,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          separatorBuilder: (_, __) => Divider(
            color: theme.dividerColor.withOpacity(0.25),
            height: 1,
          ),
          itemBuilder: (context, index) =>
              _buildCartItem(context, _cart.items[index]),
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

  /// Editable quantity.
  ///
  /// Typing beats tapping + nineteen times, which is a real pattern for a
  /// trade customer ordering a box of blanks. The field commits on blur or
  /// submit rather than per keystroke — a PATCH per digit would fire three
  /// requests for "120" and the middle one could lose a race.
  Widget _buildQtyField(CartItem item, bool busy) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final controller = _qtyControllers.putIfAbsent(
      item.id,
          () => TextEditingController(text: '${item.quantity}'),
    );

    // Server is the source of truth: if another device changed the quantity,
    // reflect it — but never while the customer is mid-edit.
    final focus = _qtyFocus.putIfAbsent(item.id, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) _commitQuantity(item, controller.text);
      });
      return node;
    });

    if (!focus.hasFocus && controller.text != '${item.quantity}') {
      controller.text = '${item.quantity}';
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roundIcon(
            icon: Icons.remove,
            onTap: busy || item.quantity <= 1
                ? null
                : () => _changeQuantity(item, -1),
            disabled: busy || item.quantity <= 1,
            isDark: isDark,
          ),
          SizedBox(
            width: 44,
            child: busy
                ? const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : TextField(
              controller: controller,
              focusNode: focus,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : primaryColor,
              ),
              onSubmitted: (value) => _commitQuantity(item, value),
            ),
          ),
          _roundIcon(
            icon: Icons.add,
            onTap: busy ? null : () => _changeQuantity(item, 1),
            disabled: busy,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Applies a typed quantity. Empty or zero removes the line, matching what
  /// the API does with quantity 0.
  Future<void> _commitQuantity(CartItem item, String raw) async {
    final parsed = int.tryParse(raw.trim());

    if (parsed == null || parsed == item.quantity) {
      _qtyControllers[item.id]?.text = '${item.quantity}';
      return;
    }

    if (parsed < 1) {
      await _removeItem(item);
      return;
    }

    setState(() => _busyItems.add(item.id));

    try {
      final cart = await cartRepo.updateQuantity(item.id, parsed);
      if (!mounted) return;
      setState(() => _cart = cart);
    } on ApiException catch (e) {
      if (!mounted) return;
      _qtyControllers[item.id]?.text = '${item.quantity}';
      AlertService.showTopAlert(
        context,
        'Miktar güncellenemedi: ${e.message}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busyItems.remove(item.id));
    }
  }

  Widget _buildQtyPill({
    required int quantity,
    required bool busy,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final textColor = isDark ? Colors.white : primaryColor;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _roundIcon(
            icon: Icons.remove,
            onTap: busy || quantity <= 1 ? null : onMinus,
            disabled: busy || quantity <= 1,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Center(
              child: busy
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(
                '$quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _roundIcon(
            icon: Icons.add,
            onTap: busy ? null : onPlus,
            disabled: busy,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({
    required IconData icon,
    VoidCallback? onTap,
    bool disabled = false,
    required bool isDark,
  }) {
    final Color bg = disabled
        ? (isDark ? Colors.white10 : Colors.grey.shade200)
        : (isDark ? Colors.white12 : Colors.white);

    final Color border = disabled
        ? (isDark ? Colors.white12 : Colors.grey.shade300)
        : (isDark ? Colors.white24 : Colors.black12);

    final Color iconColor =
    disabled ? Colors.grey : (isDark ? Colors.white : blueColor);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final busy = _busyItems.contains(item.id);

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _removeItem(item),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Sil',
          ),
        ],
      ),
      child: InkWell(
        onTap: item.slug == null
            ? null
            : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreenV2(slug: item.slug!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white,
                    child: item.image != null && item.image!.isNotEmpty
                        ? Image.network(
                      item.image!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                    )
                        : const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: busy ? null : () => _removeItem(item),
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red.withOpacity(0.8),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (item.isPreorder)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Ön Sipariş',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        _buildQtyField(item, busy),
                        const Spacer(),
                        // unit_price and line_total are null for guests, so
                        // the whole price block is conditional.
                        if (item.lineTotal != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item.quantity > 1 && item.unitPrice != null)
                                Text(
                                  'Birim: ${_cart.formatted(item.unitPrice)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                    isDark ? Colors.white70 : primaryColor,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                _cart.formatted(item.lineTotal),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : primaryColor,
                                ),
                              ),
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

  Widget _buildBottomBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final barBg = isDark ? theme.cardColor : Colors.white;

    final canCheckout = !isLoading && isLoggedIn && !_cart.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: barBg,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cart.freeShipping)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text('Ücretsiz kargo',
                        style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),

            if (_cart.priceVisible && (_cart.discount ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('İndirim', style: TextStyle(fontSize: 13)),
                    Text(
                      '-${_cart.formatted(_cart.discount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Toplam',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black,
                          ),
                        ),
                        // KDV and shipping are added server-side at checkout
                        // and there's no quote endpoint to preview them, so
                        // this is the net subtotal, labelled as such.
                        Text(
                          _cart.priceVisible
                              ? '${_cart.formatted(_cart.subtotal)} + KDV'
                              : '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        canCheckout ? blueColor : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: canCheckout ? _checkout : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Sepeti Onayla',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}