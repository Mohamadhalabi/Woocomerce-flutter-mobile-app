import 'package:flutter/material.dart';
import 'package:shop/components/buy_full_ui_kit.dart';

class OrdersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const OrdersScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Siparişlerim")),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            title: Text("Sipariş #${order['id']}"),
            subtitle: Text("Durum: ${order['status']}"),
            trailing: Text("${order['total']} ${order['currency_symbol'] ?? '₺'}"),
          );
        },
      ),
    );
  }
}