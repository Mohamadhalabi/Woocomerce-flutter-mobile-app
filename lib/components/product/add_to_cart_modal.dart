import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // ✅ Added this
import 'package:shop/screens/category/category_products_screen.dart';

import '../../constants.dart';
import '../../services/cart_service.dart';
import '../../services/alert_service.dart';

class AddToCartModal extends StatefulWidget {
  final int productId;
  final String title;
  final double price;
  final double? salePrice;
  final String sku;
  final bool isInStock;
  final String image;
  final String currencySymbol;
  final String category;
  final int categoryId;

  const AddToCartModal({
    super.key,
    required this.productId,
    required this.title,
    required this.price,
    this.salePrice,
    required this.sku,
    required this.category,
    required this.isInStock,
    required this.image,
    required this.currencySymbol,
    required this.categoryId,
  });

  @override
  State<AddToCartModal> createState() => _AddToCartModalState();
}

class _AddToCartModalState extends State<AddToCartModal> {
  int quantity = 1;
  final TextEditingController _controller = TextEditingController(text: '1');
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Check if token exists and is valid (not expired)
    bool valid = false;
    if (token != null && token.isNotEmpty) {
      if (!JwtDecoder.isExpired(token)) {
        valid = true;
      } else {
        // Cleanup expired token silently
        await prefs.remove('auth_token');
        await prefs.remove('user_id');
      }
    }

    if (mounted) {
      setState(() {
        isLoggedIn = valid;
      });
    }
  }

  void _updateQuantity(int change) {
    final newQty = (quantity + change).clamp(1, 999);
    if (newQty != quantity) {
      setState(() {
        quantity = newQty;
        _controller.text = quantity.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _handleAddToCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    // 1. AUTO-LOGOUT CHECK: If token exists but is expired, remove it.
    if (token != null && JwtDecoder.isExpired(token)) {
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      token = null;
      if (mounted) setState(() => isLoggedIn = false);
    }

    try {
      if (token != null) {
        // --- Attempt to add to Server Cart ---
        await CartService.addToWooCart(token, widget.productId, quantity);
      } else {
        // --- Add to Guest Cart ---
        await _addToGuestCart();
      }

      // Success
      if (!mounted) return;
      Navigator.pop(context);
      AlertService.showTopAlert(
        context,
        'Ürün sepete eklendi',
        isError: false,
        showGoToCart: true,
      );
    } catch (e) {
      // 2. FAIL-SAFE: If server rejects token (401/403), retry as Guest
      if (token != null && e.toString().contains('Auth Error')) {
        debugPrint("Server rejected token. Retrying as Guest...");

        // Clear bad data
        await prefs.remove('auth_token');
        await prefs.remove('user_id');
        if (mounted) setState(() => isLoggedIn = false);

        // Retry immediately as guest
        try {
          await _addToGuestCart();
          if (!mounted) return;
          Navigator.pop(context);
          AlertService.showTopAlert(
            context,
            'Ürün sepete eklendi (Misafir)',
            isError: false,
            showGoToCart: true,
          );
          return; // Exit successfully
        } catch (innerError) {
          // If guest add also fails
          if (!mounted) return;
          AlertService.showTopAlert(
            context,
            'Hata: ${innerError.toString()}',
            isError: true,
          );
        }
      } else {
        // Genuine Error
        if (!mounted) return;
        AlertService.showTopAlert(
          context,
          'Sepete ekleme hatası: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // Helper for guest cart logic to avoid code duplication
  Future<void> _addToGuestCart() async {
    await CartService.addItemToGuestCart(
      productId: widget.productId,
      title: widget.title,
      image: widget.image,
      quantity: quantity,
      price: widget.price,
      salePrice: widget.salePrice,
      sku: widget.sku,
      category: widget.category,
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = widget.salePrice != null && (widget.salePrice! < widget.price);
    final finalPrice = hasDiscount ? widget.salePrice! : widget.price;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Material(
        color: theme.brightness == Brightness.light ? Colors.white : theme.scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Column(
                  children: [
                    // Drag handle + close
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Kapat',
                            icon: Icon(Icons.close, color: theme.iconTheme.color),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Container(
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? Colors.white
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Image.network(
                                    widget.image,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, err, stack) =>
                                        Icon(Icons.broken_image, size: 40, color: theme.iconTheme.color),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Category
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryProductsScreen(
                                      id: widget.categoryId,
                                      title: widget.category,
                                      filterType: "category",
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                widget.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: blueColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              widget.title,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // SKU + Stock badge
                            Row(
                              children: [
                                SelectableText(
                                  widget.sku,
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _StockChip(inStock: widget.isInStock),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Price
                            if (isLoggedIn)
                              (hasDiscount
                                  ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.currencySymbol}${_fmt(finalPrice)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.currencySymbol}${_fmt(widget.price)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              )
                                  : Text(
                                '${widget.currencySymbol}${_fmt(widget.price)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ))
                            else
                              Text(
                                'Fiyatları görmek için giriş yapın',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 12),
                            // --- Quantity + Sepete Ekle in the SAME ROW ---
                            Row(
                              children: [
                                // Stepper expands on the left
                                Expanded(
                                  child: _QtyStepper(
                                    controller: _controller,
                                    value: quantity,
                                    onMinus: () => _updateQuantity(-1),
                                    onPlus: () => _updateQuantity(1),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val);
                                      if (parsed != null) {
                                        final clamped = parsed.clamp(1, 999);
                                        setState(() => quantity = clamped);
                                        _controller.text = clamped.toString();
                                        _controller.selection = TextSelection.fromPosition(
                                          TextPosition(offset: _controller.text.length),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Button fills the remaining space
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: widget.isInStock ? _handleAddToCart : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: blueColor,
                                        disabledBackgroundColor: theme.disabledColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.isInStock ? 'SEPETE EKLE' : 'STOKTA YOK',
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Divider(color: theme.dividerColor.withOpacity(0.6)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Stepper and Chip widgets remain the same...
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.controller,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.light ? Colors.white : theme.cardColor;
    final border = theme.dividerColor.withOpacity(0.35);
    final isMin = value <= 1;
    final isMax = value >= 999;

    Widget buildSegment({
      required Widget child,
      BorderRadius? radius,
      bool showRightBorder = true,
      bool showLeftBorder = false,
    }) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: bg,
          border: Border(
            left: showLeftBorder ? BorderSide(color: border) : BorderSide.none,
            right: showRightBorder ? BorderSide(color: border) : BorderSide.none,
          ),
        ),
        child: child,
      );
    }

    Widget tapBtn({
      required IconData icon,
      required VoidCallback? onTap,
      required bool disabled,
      BorderRadius? radius,
      bool showRightBorder = true,
      bool showLeftBorder = false,
    }) {
      return buildSegment(
        radius: radius,
        showRightBorder: showRightBorder,
        showLeftBorder: showLeftBorder,
        child: InkWell(
          borderRadius: radius ?? BorderRadius.zero,
          onTap: disabled ? null : onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 18,
              color: disabled ? theme.disabledColor : blueColor,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tapBtn(
            icon: Icons.remove_rounded,
            onTap: onMinus,
            disabled: isMin,
            radius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            showLeftBorder: false,
            showRightBorder: true,
          ),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty) {
                    final n = int.tryParse(val);
                    if (n != null) {
                      final clamped = n.clamp(1, 999);
                      if (clamped.toString() != val) {
                        controller.text = clamped.toString();
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    }
                  }
                  onChanged(controller.text);
                },
                onSubmitted: (val) {
                  final n = int.tryParse(val) ?? 1;
                  final clamped = n.clamp(1, 999);
                  controller.text = clamped.toString();
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                  onChanged(controller.text);
                },
              ),
            ),
          ),
          tapBtn(
            icon: Icons.add_rounded,
            onTap: onPlus,
            disabled: isMax,
            radius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            showLeftBorder: true,
            showRightBorder: false,
          ),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.inStock});
  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = inStock ? Colors.green : Colors.red;
    final bg = color.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        inStock ? 'Stokta Var' : 'Stokta Yok',
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}