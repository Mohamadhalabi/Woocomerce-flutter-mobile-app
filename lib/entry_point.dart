import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/components/common/drawer_v2.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/cart/views/cart_screen_v2.dart';
import 'package:shop/screens/home/views/home_screen_v2.dart';
import 'components/common/main_scaffold.dart';
import 'package:upgrader/upgrader.dart';
import 'package:shop/screens/discover/views/discover_screen_v2.dart';
import 'package:shop/screens/store/views/store_screen_v2.dart';


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

  // HISTORY STACK: keeps track of visited tabs. Starts at [0] — Home.
  final List<int> _navigationHistory = [0];

  DateTime? currentBackPressTime;

  // NOTE: _homeKey removed — HomeScreenV2 manages its own refresh internally
  // and doesn't expose a HomeScreenState.
  final GlobalKey<DiscoverScreenV2State> _discoverKey = GlobalKey<DiscoverScreenV2State>();
  final GlobalKey<StoreScreenV2State> _storeKey = GlobalKey<StoreScreenV2State>();

  // MIGRATED: CartScreenV2 talks to the Laravel cart. Its state class exposes
  // the same loadCart() and refreshWithSkeleton() the old one did.
  final GlobalKey<CartScreenV2State> _cartKey = GlobalKey<CartScreenV2State>();

  final GlobalKey<ProfileScreenState> _profileKey =
  GlobalKey<ProfileScreenState>();

  Widget? _storeScreen;
  Widget? _cartScreen;
  Widget? _profileScreen;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    if (_currentIndex != 0) {
      _navigationHistory.add(_currentIndex);
    }

    _initializeTab(_currentIndex);
  }

  void _initializeTab(int index) {
    switch (index) {
      case 2:
        if (_storeScreen == null) {
          _storeScreen = StoreScreen(key: _storeKey);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _storeKey.currentState?.loadStoreData();
          });
        }
        break;
      case 3:
      // CartScreenV2 loads itself in initState — no post-frame call needed.
        _cartScreen = CartScreenV2(key: _cartKey);
        break;
      case 4:
        _profileScreen = ProfileScreen(
          key: _profileKey,
          onLocaleChange: widget.onLocaleChange,
          onTabChange: (newIndex) => _changeTab(newIndex),
          searchController: _searchController,
          initialUserData: widget.initialUserData,
        );
        break;
    }
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
      // HomeScreenV2 refreshes itself via pull-to-refresh.
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

  void _changeTab(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
      _navigationHistory.add(index);

      if (index == 2) {
        if (_storeScreen == null) {
          _storeScreen = StoreScreenV2(key: _storeKey);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _storeKey.currentState?.loadStoreData();
          });
        }
      }

      if (index == 3) {
        if (_cartKey.currentState != null) {
          _cartKey.currentState!.refreshWithSkeleton();
        } else {
          _cartScreen = CartScreenV2(key: _cartKey);
        }
      }

      if (index == 4 && _profileScreen == null) {
        _profileScreen = ProfileScreen(
          key: _profileKey,
          onLocaleChange: widget.onLocaleChange,
          onTabChange: (newIndex) => _changeTab(newIndex),
          searchController: _searchController,
          initialUserData: widget.initialUserData,
        );
      }
    });

    _refreshTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // MIGRATED: home reads from the new Laravel API.
      //
      // The old "Tümünü Gör" callbacks are gone on purpose — they navigated to
      // StoreScreen, which is still on WooCommerce, and onViewAllEmulators
      // passed the Woo category id 62, which doesn't exist in the new
      // database. They get reconnected (using the slug 'emulatorler') when the
      // store screen is migrated.
      const HomeScreenV2(),
      DiscoverScreenV2(key: _discoverKey),
      _storeScreen ?? const SizedBox(),
      _cartScreen ?? const SizedBox(),
      _profileScreen ?? const SizedBox(),
    ];

    return UpgradeAlert(
      showIgnore: false,
      showLater: false,
      showReleaseNotes: false,
      dialogStyle: UpgradeDialogStyle.cupertino,
      upgrader: Upgrader(languageCode: 'tr'),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;

          if (_navigationHistory.length > 1) {
            setState(() {
              _navigationHistory.removeLast();
              _currentIndex = _navigationHistory.last;
            });
            _refreshTab(_currentIndex);
            return;
          }

          final now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime!) >
                  const Duration(seconds: 2)) {
            currentBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Çıkmak için tekrar geri basın'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        },
        child: MainScaffold(
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
          onTabChange: (index) => _changeTab(index),
          onSearchTap: () => _changeTab(1),
          searchController: _searchController,
          showAppBar: _currentIndex != 1,
          drawer: CustomDrawerV2(
            onNavigateToIndex: (index) {
              _changeTab(index);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}