import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const SearchScreen({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔼 No AppBar
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔙 Back + 🔍 Search Input
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Ürün ara...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // You can add filters, recent searches, etc. here
            ],
          ),
        ),
      ),
      // 🔽 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: (index) {
          if (index != widget.currentIndex) {
            widget.onTabChange(index);
            Navigator.pop(context); // Go back to main screen
          }
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Mağaza"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Kaydedilenler"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}