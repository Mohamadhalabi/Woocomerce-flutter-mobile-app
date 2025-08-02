import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    setState(() {
      isLoggedIn = prefs.getString('auth_token') != null;
    });
  }

  void _updateQuantity(int change) {
    final newQty = (quantity + change).clamp(1, 999);
    setState(() {
      quantity = newQty;
      _controller.text = quantity.toString();
    });
  }

  Future<void> _handleAddToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      if (token != null) {
        // Logged-in user
        await CartService.addToWooCart(token, widget.productId, quantity);
      } else {
        // Guest cart
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

      if (mounted) {
        Navigator.pop(context);
        AlertService.showTopAlert(context, 'Ürün sepete eklendi', isError: false);
      }
    } catch (e) {
      if (mounted) {
        AlertService.showTopAlert(
          context,
          'Sepete ekleme hatası: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double finalPrice = widget.salePrice ?? widget.price;
    final bool hasDiscount =
        widget.salePrice != null && widget.salePrice! < widget.price;

    final outlineBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(6),
    );

    final focusedBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: blueColor),
      borderRadius: BorderRadius.circular(6),
    );

    return Container(
      color: Colors.white, // ✅ White background
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                widget.image,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),

            // Price
            isLoggedIn
                ? hasDiscount
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.currencySymbol}${widget.salePrice!.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  "${widget.currencySymbol}${widget.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            )
                : Text(
              "${widget.currencySymbol}${widget.price.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            )
                : const Text(
              "Fiyatları görmek için giriş yapın",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            // SKU & Stock
            Row(
              children: [
                Text(
                  "Stok Kodu: ${widget.sku}",
                  style: const TextStyle(
                      color: blueColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.isInStock ? "Stokta Var" : "Stokta Yok",
                  style: TextStyle(
                    color: widget.isInStock ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text("Adet Seçiniz:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Quantity Selector
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _updateQuantity(-1),
                    icon: const Icon(Icons.remove, color: blueColor),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  height: 40,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.2),
                    decoration: InputDecoration(
                      border: outlineBorder,
                      focusedBorder: focusedBorder,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        setState(() => quantity = parsed < 1 ? 1 : parsed);
                        _controller.text = quantity.toString();
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _updateQuantity(1),
                    icon: const Icon(Icons.add, color: blueColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: blueColor,
                    ),
                    child: const Text("ŞİMDİ SATIN AL"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isInStock ? _handleAddToCart : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: widget.isInStock
                          ? Colors.grey.shade200
                          : Colors.grey.shade300,
                    ),
                    child: Text(
                      widget.isInStock ? "SEPETE EKLE" : "STOKTA YOK",
                      style: const TextStyle(color: Colors.black54),
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