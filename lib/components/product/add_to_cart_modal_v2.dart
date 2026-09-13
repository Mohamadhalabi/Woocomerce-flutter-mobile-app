// lib/components/product/add_to_cart_modal_v2.dart
//
// Same sheet as the original, driven by the new API's ProductModel.
//
// Gone from the old version: the JWT expiry check and the guest-cart fallback.
// Sanctum tokens don't decode client-side, and guests get a real server cart
// via X-Cart-Token — so there's one code path now instead of three.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/catalog_product.dart';
import '../../screens/category/category_products_screen_v2.dart';
import '../../services/cart_actions.dart';

class AddToCartModalV2 extends StatefulWidget {
  const AddToCartModalV2({
    super.key,
    required this.product,
    this.initialQuantity = 1,
  });

  final ProductModel product;
  final int initialQuantity;

  /// Opens the sheet. Returns true when something was added.
  static Future<bool> show(
    BuildContext context,
    ProductModel product, {
    int initialQuantity = 1,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToCartModalV2(
        product: product,
        initialQuantity: initialQuantity,
      ),
    );

    return result ?? false;
  }

  @override
  State<AddToCartModalV2> createState() => _AddToCartModalV2State();
}

class _AddToCartModalV2State extends State<AddToCartModalV2> {
  late int _quantity = widget.initialQuantity;
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initialQuantity}');

  bool _busy = false;

  ProductModel get product => widget.product;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateQuantity(int change) {
    final next = (_quantity + change).clamp(1, 999);
    if (next == _quantity) return;

    setState(() {
      _quantity = next;
      _controller.text = '$next';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Closes first so the alert isn't hidden behind the sheet.
    final navigator = Navigator.of(context);
    final added = await CartActions.add(
      context,
      productId: product.id,
      quantity: _quantity,
    );

    if (!mounted) return;
    if (added) {
      navigator.pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Material(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : theme.scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        icon:
                            Icon(Icons.close, color: theme.iconTheme.color),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _image(theme),
                        const SizedBox(height: 12),
                        if (product.category != null) _categoryLink(theme),
                        const SizedBox(height: 12),
                        Text(
                          product.title,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SelectableText(
                              product.sku,
                              style: const TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _StockChip(inStock: product.inStock),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _price(theme),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QtyStepper(
                                controller: _controller,
                                value: _quantity,
                                onMinus: () => _updateQuantity(-1),
                                onPlus: () => _updateQuantity(1),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null) {
                                    setState(() =>
                                        _quantity = parsed.clamp(1, 999));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed:
                                      product.inStock && !_busy ? _add : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: blueColor,
                                    disabledBackgroundColor:
                                        theme.disabledColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.shopping_cart_outlined,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              product.inStock
                                                  ? 'SEPETE EKLE'
                                                  : 'STOKTA YOK',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _image(ThemeData theme) {
    return Container(
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
          child: product.thumb == null
              ? Icon(Icons.image_not_supported,
                  size: 40, color: theme.iconTheme.color)
              : Image.network(
                  product.thumb!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.broken_image,
                      size: 40, color: theme.iconTheme.color),
                ),
        ),
      ),
    );
  }

  Widget _categoryLink(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Card resources give the category NAME only, not its slug, so there's
        // nothing to navigate by from here. Tapping is a no-op until the API
        // includes the slug — see the note in the migration doc.
      },
      child: Text(
        product.category!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _price(ThemeData theme) {
    // Zero is treated as hidden: the detail endpoint returns 0.00 where the
    // list endpoint returns null.
    final visible =
        product.priceVisible && product.price != null && product.price! > 0;

    if (!visible) {
      return Text(
        'Fiyatları görmek için giriş yapın',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (product.isOnSale) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            product.formattedPrice,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            product.formattedOldPrice,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+ KDV',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          product.formattedPrice,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '+ KDV',
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

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
    final bg =
        theme.brightness == Brightness.light ? Colors.white : theme.cardColor;
    final border = theme.dividerColor.withOpacity(0.35);

    Widget tapBtn({
      required IconData icon,
      required VoidCallback onTap,
      required bool disabled,
      required BorderRadius radius,
      required bool leftBorder,
      required bool rightBorder,
    }) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: bg,
          border: Border(
            left: leftBorder ? BorderSide(color: border) : BorderSide.none,
            right: rightBorder ? BorderSide(color: border) : BorderSide.none,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
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
            disabled: value <= 1,
            radius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            leftBorder: false,
            rightBorder: true,
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
                onChanged: onChanged,
              ),
            ),
          ),
          tapBtn(
            icon: Icons.add_rounded,
            onTap: onPlus,
            disabled: value >= 999,
            radius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            leftBorder: true,
            rightBorder: false,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
