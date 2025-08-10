import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';

class AlertService {
  static void showTopAlert(
      BuildContext context,
      String message, {
        bool isError = false,
        bool showGoToCart = false,
        Duration duration = const Duration(seconds: 5),
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.close_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

                if (showGoToCart)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                    label: const Text(
                      "Sepete Git",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
                      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.white.withOpacity(0.06),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.white.withOpacity(0.12),
                      ),
                    ),
                    onPressed: () {
                      overlayEntry.remove();
                      Navigator.pushNamed(context, cartScreenRoute);
                    },
                  ),

                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  static Future<void> showErrorDialog(
      BuildContext context, String title, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
