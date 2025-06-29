import 'package:flutter/material.dart';

import '../../screens/search/views/search_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
        ),
      ),
      title: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10), // adjust value as needed
          child: Image.asset(
            'assets/logo/aanahtar-logo.webp',
            height: 50,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(
                  currentIndex: 0, // or whatever tab you're on
                  onTabChange: (index) {
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}