import 'package:flutter/material.dart';
import '../../constants.dart';

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

    return AppBar(
      // ✅ Use theme colors instead of hardcoded white
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
            // ✅ Theme‑aware background for search box
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
        IconButton(
          icon: const Icon(Icons.notifications_none, color: primaryColor),
          onPressed: onBellTap,
        ),
      ],
    );
  }
}