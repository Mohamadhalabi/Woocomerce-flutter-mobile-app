import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/notification_provider.dart';
import 'package:shop/route/screen_export.dart'; // ✅ Needed for productDetailsScreenRoute

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler"),
        actions: [
          if (provider.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                for (var item in provider.items) {
                  provider.markAsRead(item.id);
                }
              },
            )
        ],
      ),
      body: provider.items.isEmpty
          ? const Center(child: Text("Henüz bildirim yok"))
          : ListView.builder(
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final item = provider.items[index];
          return ListTile(
            leading: Icon(
              item.isRead ? Icons.notifications_none : Icons.notifications_active,
              color: item.isRead ? Colors.grey : Colors.blue,
            ),
            title: Text(item.title),
            subtitle: Text(item.body),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => provider.deleteNotification(item.id),
            ),
            onTap: () {
              provider.markAsRead(item.id);

              // ✅ Check for ID and navigate
              if (item.productId != null) {
                Navigator.pushNamed(
                  context,
                  productDetailsScreenRoute,
                  arguments: item.productId,
                );
              }
            },
          );
        },
      ),
    );
  }
}