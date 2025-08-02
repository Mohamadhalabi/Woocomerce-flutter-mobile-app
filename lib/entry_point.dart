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
  final Map<String, dynamic>? initialDrawerData;
  final Map<String, dynamic>? initialUserData;

  const EntryPoint({
    super.key,
    required this.onLocaleChange,
    this.initialIndex = 0,
    this.initialDrawerData,
    this.initialUserData,
  });

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  late int _currentIndex;
  final TextEditingController _searchController = TextEditingController();

  // Keys for refresh actions
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<DiscoverScreenState> _discoverKey = GlobalKey<DiscoverScreenState>();
  final GlobalKey<StoreScreenState> _storeKey = GlobalKey<StoreScreenState>();
  final GlobalKey<CartScreenState> _cartKey = GlobalKey<CartScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  // 🆕 Lazy-loaded screens
  Widget? _cartScreen;

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
        _storeKey.currentState?.refresh();
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
    final pages = [
      HomeScreen(
        key: _homeKey,
        initialDrawerData: widget.initialDrawerData,
      ),
      DiscoverScreen(key: _discoverKey),
      StoreScreen(key: _storeKey),

      // 🆕 Only create CartScreen when needed
      _cartScreen ?? const SizedBox(),

      ProfileScreen(
        key: _profileKey,
        onLocaleChange: widget.onLocaleChange,
        onTabChange: (index) {
          setState(() => _currentIndex = index);
          _refreshTab(index);
        },
        searchController: _searchController,
        initialUserData: widget.initialUserData,
      ),
    ];

    return MainScaffold(
      body: PageTransitionSwitcher(
        duration: defaultDuration,
        transitionBuilder: (child, animation, secondaryAnimation) =>
            FadeThroughTransition(
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
        setState(() {
          _currentIndex = index;

          // 🆕 Create CartScreen only when user first goes to index 3
          if (index == 3 && _cartScreen == null) {
            _cartScreen = CartScreen(key: _cartKey);
          }
        });

        _refreshTab(index);
      },
      onSearchTap: () {
        setState(() => _currentIndex = 1);
        _refreshTab(1);
      },
      searchController: _searchController,
      showAppBar: _currentIndex != 1,
      drawer: CustomDrawer(
        initialData: widget.initialDrawerData,
        onNavigateToIndex: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 3 && _cartScreen == null) {
              _cartScreen = CartScreen(key: _cartKey);
            }
          });
          _refreshTab(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}