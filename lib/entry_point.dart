import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'components/common/drawer.dart';
import 'components/common/main_scaffold.dart';
import 'screens/cart/cart_screen.dart';

class EntryPoint extends StatefulWidget {
  final Function(String) onLocaleChange;
  final int initialIndex;

  const EntryPoint({
    super.key,
    required this.onLocaleChange,
    this.initialIndex = 0,
  });

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  late int _currentIndex;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
        searchController: _searchController,
      ),
    ];

    return MainScaffold(
      body: PageTransitionSwitcher(
        duration: defaultDuration,
        transitionBuilder: (child, animation, secondaryAnimation) => FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
        child: pages[_currentIndex],
      ),
      currentIndex: _currentIndex,
      onTabChange: (index) {
        setState(() => _currentIndex = index);
      },
      onSearchTap: () {
        setState(() => _currentIndex = 1);
      },
      searchController: _searchController,
      showAppBar: _currentIndex != 1,
      drawer: CustomDrawer(
        onNavigateToIndex: (int index) {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }
}