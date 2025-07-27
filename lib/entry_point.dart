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

  // 🔑 GlobalKeys for accessing refreshable screen states
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<DiscoverScreenState> _discoverKey = GlobalKey<DiscoverScreenState>();
  final GlobalKey<BookmarkScreenState> _bookmarkKey = GlobalKey<BookmarkScreenState>();
  final GlobalKey<CartScreenState> _cartKey = GlobalKey<CartScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        _homeKey.currentState?.refresh();
        break;
      case 1:
        _discoverKey.currentState?.refresh();
        break;
      case 2:
        _bookmarkKey.currentState?.refresh();
        break;
      case 3:
        _cartKey.currentState?.loadCart();
        break;
      case 4:
        _profileKey.currentState?.refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(key: _homeKey),
      DiscoverScreen(key: _discoverKey),
      BookmarkScreen(key: _bookmarkKey),
      CartScreen(key: _cartKey),
      ProfileScreen(
        key: _profileKey,
        onLocaleChange: widget.onLocaleChange,
        onTabChange: (index) {
          setState(() => _currentIndex = index);
          _refreshTab(index); // refresh from within profile too
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
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      currentIndex: _currentIndex,
      onTabChange: (index) {
        setState(() => _currentIndex = index);
        _refreshTab(index);
      },
      onSearchTap: () {
        setState(() => _currentIndex = 1);
        _refreshTab(1);
      },
      searchController: _searchController,
      showAppBar: _currentIndex != 1,
      drawer: CustomDrawer(
        onNavigateToIndex: (index) {
          setState(() => _currentIndex = index);
          _refreshTab(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
