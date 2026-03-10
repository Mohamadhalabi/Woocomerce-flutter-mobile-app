import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for nice dates
import '../../providers/notification_provider.dart';
import '../../constants.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ✅ Listen to the provider
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler"),
        actions: [
          if (provider.items.isNotEmpty)
            TextButton(
              onPressed: () => provider.items.forEach((item) => provider.markAsRead(item.id)),
              child: const Text("Hepsini oku", style: TextStyle(color: primaryColor)),
            ),
        ],
      ),
      body: provider.items.isEmpty
          ? _buildEmptyState(theme)
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${provider.items.length} Bildirim"),
                TextButton(
                  onPressed: () => provider.clearAll(), // Ensure you add clearAll to your provider
                  child: const Text("Temizle", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return Dismissible(
                  key: Key(item.id),
                  onDismissed: (_) => provider.deleteNotification(item.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    color: item.isRead ? null : primaryColor.withOpacity(0.05),
                    child: ListTile(
                      leading: Icon(
                        item.isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: item.isRead ? Colors.grey : primaryColor,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () => provider.markAsRead(item.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: theme.dividerColor),
          const SizedBox(height: 16),
          const Text("Henüz bildiriminiz bulunmuyor."),
        ],
      ),
    );
  }
}