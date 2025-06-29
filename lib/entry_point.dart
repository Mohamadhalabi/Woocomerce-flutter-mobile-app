import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'screens/profile/views/profile_screen.dart';
import 'components/common/app_bar.dart';
import 'components/common/drawer.dart';
import 'screens/cart/cart_screen.dart'; // ✅ Add this line

class EntryPoint extends StatefulWidget {
  final Function(String) onLocaleChange;

  const EntryPoint({super.key, required this.onLocaleChange});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      const DiscoverScreen(),
      const BookmarkScreen(),
      const CartScreen(),
      ProfileScreen(
        onLocaleChange: widget.onLocaleChange,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    ];

    return Scaffold(
      appBar: const CustomAppBar(),
      endDrawer: const CustomEndDrawer(),
      body: PageTransitionSwitcher(
        duration: defaultDuration,
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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