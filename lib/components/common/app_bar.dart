import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../providers/notification_provider.dart';

class CustomSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final VoidCallback onBellTap;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchTap;

  const CustomSearchAppBar({
    super.key,
    required this.controller,
    required this.onBellTap,
    required this.onSearchSubmitted,
    required this.onSearchTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Listen to the unread count from the provider to rebuild the badge automatically
    final unreadCount = context.watch<NotificationProvider>().items.where((i) => !i.isRead).length;

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: 4,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black38,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: theme.iconTheme.color),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: GestureDetector(
        onTap: onSearchTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.white70,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Ürün ara...",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              // ✅ UI Tip: Using 'Icons.notifications' when unreadCount > 0 provides visual feedback
              icon: Icon(
                unreadCount > 0 ? Icons.notifications : Icons.notifications_none,
                color: primaryColor,
              ),
              onPressed: onBellTap,
            ),
            // ✅ Conditional rendering: The badge only takes up space if there are unread items
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}