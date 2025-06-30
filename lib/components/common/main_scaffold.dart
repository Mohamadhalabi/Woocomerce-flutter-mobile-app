import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'app_bar.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChange;
  final TextEditingController searchController;
  final Widget? drawer;

  const MainScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChange,
    required this.searchController,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomSearchAppBar(
        controller: searchController,
        onBellTap: () {},
        onSearchSubmitted: (value) => debugPrint('Search: $value'),
      ),
      drawer: drawer,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabChange,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Kaydedilenler"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}