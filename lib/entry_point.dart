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

  // Keys for refresh/load actions
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<DiscoverScreenState> _discoverKey = GlobalKey<DiscoverScreenState>();
  final GlobalKey<StoreScreenState> _storeKey = GlobalKey<StoreScreenState>();
  final GlobalKey<CartScreenState> _cartKey = GlobalKey<CartScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  // Lazy-loaded screens
  Widget? _storeScreen;
  Widget? _cartScreen;
  Widget? _profileScreen;

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
      // Home
      HomeScreen(
        key: _homeKey,
        initialDrawerData: widget.initialDrawerData,
        onViewAllNewArrival: () {
          setState(() {
            _currentIndex = 2;
            if (_storeScreen == null) {
              _storeScreen = StoreScreen(key: _storeKey);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _storeKey.currentState?.loadStoreData();
              });
            } else {
              _storeKey.currentState?.switchMode(onSale: false, categoryId: null);
            }
          });
        },
        onViewAllFlashSale: () {
          setState(() {
            _currentIndex = 2;
            if (_storeScreen == null) {
              _storeScreen = StoreScreen(key: _storeKey, onSale: true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _storeKey.currentState?.loadStoreData();
              });
            } else {
              _storeKey.currentState?.switchMode(onSale: true, categoryId: null);
            }
          });
        },
        onViewAllEmulators: () {
          setState(() {
            _currentIndex = 2;
            const int emulatorCategoryId = 62; // ✅ your emulator category ID
            if (_storeScreen == null) {
              _storeScreen = StoreScreen(
                key: _storeKey,
                onSale: false, // explicitly set onSale to false
                categoryId: emulatorCategoryId,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _storeKey.currentState?.loadStoreData();
              });
            } else {
              _storeKey.currentState?.switchMode(
                onSale: false, // explicitly set to false for emulators
                categoryId: emulatorCategoryId,
              );
            }
          });
        },
      ),

      // Discover
      DiscoverScreen(key: _discoverKey),

      // Store (lazy)
      _storeScreen ?? const SizedBox(),

      // Cart (lazy)
      _cartScreen ?? const SizedBox(),

      // Profile (lazy)
      _profileScreen ?? const SizedBox(),
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

            if (index == 2) {
              if (_storeScreen == null) {
                _storeScreen = StoreScreen(key: _storeKey);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _storeKey.currentState?.loadStoreData();
                });
              }
              else if ((_storeScreen as StoreScreen).onSale ||
                  (_storeScreen as StoreScreen).categoryId != null) {
                _storeKey.currentState?.switchMode(onSale: false, categoryId: null);
              }
            }


            if (index == 3 && _cartScreen == null) {
              _cartScreen = CartScreen(key: _cartKey);
            }

            if (index == 4 && _profileScreen == null) {
              _profileScreen = ProfileScreen(
                key: _profileKey,
                onLocaleChange: widget.onLocaleChange,
                onTabChange: (newIndex) {
                  setState(() => _currentIndex = newIndex);
                  _refreshTab(newIndex);
                },
                searchController: _searchController,
                initialUserData: widget.initialUserData,
              );
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

            if (index == 2 && _storeScreen == null) {
              _storeScreen = StoreScreen(key: _storeKey);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _storeKey.currentState?.loadStoreData();
              });
            }
            if (index == 3 && _cartScreen == null) {
              _cartScreen = CartScreen(key: _cartKey);
            }
            if (index == 4 && _profileScreen == null) {
              _profileScreen = ProfileScreen(
                key: _profileKey,
                onLocaleChange: widget.onLocaleChange,
                onTabChange: (newIndex) {
                  setState(() => _currentIndex = newIndex);
                  _refreshTab(newIndex);
                },
                searchController: _searchController,
                initialUserData: widget.initialUserData,
              );
            }
          });
          _refreshTab(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}