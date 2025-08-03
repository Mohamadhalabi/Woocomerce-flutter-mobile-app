import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';

class OrdersScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? orders;

  const OrdersScreen({super.key, this.orders});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    if (widget.orders != null && widget.orders!.isNotEmpty) {
      _ordersFuture = Future.value(widget.orders!);
    } else {
      _ordersFuture = ApiService.fetchUserOrders();
    }
  }

  /// Fetch order details from WooCommerce
  Future<Map<String, dynamic>> _fetchOrderDetails(int orderId) async {
    try {
      return await ApiService.fetchOrderDetails(orderId);
    } catch (e) {
      throw Exception("Sipariş detayları alınamadı: $e");
    }
  }

  /// Show details in modal
  void _showOrderDetails(int orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final details = await _fetchOrderDetails(orderId);
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) {
          final lineItems = details['line_items'] as List<dynamic>? ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text("Sipariş #$orderId"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Durum: ${details['status']}"),
                  const SizedBox(height: 8),
                  Text("Toplam: ${details['total']} ${details['currency_symbol'] ?? '₺'}"),
                  const Divider(),
                  const Text(
                    "Ürünler:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...lineItems.map((item) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 6), // more vertical space
                    leading: item['image'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['image']['src'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(Icons.image_not_supported, size: 60),
                    title: Text(
                      item['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      "Adet: ${item['quantity']}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: Text(
                      "${item['total']} ${details['currency_symbol'] ?? '₺'}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Kapat"),
              )
            ],
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      AlertService.showTopAlert(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Siparişlerim"),
        backgroundColor: blueColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Siparişler alınamadı: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz siparişiniz yok."));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("Sipariş #${order['id']}"),
                  subtitle: Text("Durum: ${order['status']}"),
                  trailing: Text(
                    "${order['total']} ${order['currency_symbol'] ?? '₺'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showOrderDetails(order['id']),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 4, // Profile tab index
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EntryPoint(
                  onLocaleChange: (_) {},
                  initialIndex: index,
                ),
              ),
            );
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: theme.unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mağaza"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }
}