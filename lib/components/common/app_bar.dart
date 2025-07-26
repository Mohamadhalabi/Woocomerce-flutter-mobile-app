import 'package:flutter/material.dart';

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
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF), // Pure white
      elevation: 4,
      scrolledUnderElevation: 1, // Prevent elevation on scroll
      surfaceTintColor: Colors.white, // Prevent default Material3 behavior
      shadowColor: Colors.black38,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: GestureDetector(
        onTap: onSearchTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: const Row(
            children: [
              Icon(Icons.search, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Ürün ara...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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
          icon: const Icon(Icons.notifications_none, color: Colors.black),
          onPressed: onBellTap,
        ),
      ],
    );
  }
}