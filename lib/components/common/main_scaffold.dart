import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'app_bar.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChange;
  final TextEditingController searchController;
  final Widget? drawer;
  final bool showAppBar;
  final VoidCallback? onSearchTap;

  const MainScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChange,
    required this.searchController,
    this.drawer,
    this.showAppBar = true,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? CustomSearchAppBar(
        controller: searchController,
        onBellTap: () {},
        onSearchSubmitted: (value) => debugPrint('Search: $value'),
        onSearchTap: onSearchTap ?? () {},
      )
          : null,
      drawer: drawer,
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: currentIndex,
          onTap: onTabChange,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
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