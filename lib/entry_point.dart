import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'components/common/drawer.dart';
import 'components/common/main_scaffold.dart';
import 'package:upgrader/upgrader.dart';

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

  // ✅ 1. HISTORY STACK: Keeps track of visited tabs
  // We start with [0] because the app starts on Home.
  final List<int> _navigationHistory = [0];

  DateTime? currentBackPressTime;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<DiscoverScreenState> _discoverKey = GlobalKey<DiscoverScreenState>();
  final GlobalKey<StoreScreenState> _storeKey = GlobalKey<StoreScreenState>();
  final GlobalKey<CartScreenState> _cartKey = GlobalKey<CartScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  Widget? _storeScreen;
  Widget? _cartScreen;
  Widget? _profileScreen;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // If initial index isn't 0, we update history start
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
        _cartScreen = CartScreen(key: _cartKey);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _cartKey.currentState?.loadCart();
        });
        break;
      case 4:
        _profileScreen = ProfileScreen(
          key: _profileKey,
          onLocaleChange: widget.onLocaleChange,
          onTabChange: (newIndex) => _changeTab(newIndex), // Helper method
          searchController: _searchController,
          initialUserData: widget.initialUserData,
        );
        break;
    }
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

  // ✅ Helper method to handle tab switching and history
  void _changeTab(int index) {
    if (_currentIndex == index) return; // Do nothing if clicking same tab

    setState(() {
      _currentIndex = index;
      // Add to history
      _navigationHistory.add(index);

      // Initialize screens logic (Copied from your original onTabChange)
      if (index == 2) {
        if (_storeScreen == null) {
          _storeScreen = StoreScreen(key: _storeKey);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _storeKey.currentState?.loadStoreData();
          });
        } else if ((_storeScreen as StoreScreen).onSale ||
            (_storeScreen as StoreScreen).categoryId != null) {
          _storeKey.currentState?.switchMode(onSale: false, categoryId: null);
        }
      }

      if (index == 3) {
        if (_cartKey.currentState != null) {
          _cartKey.currentState!.refreshWithSkeleton();
        } else {
          _cartScreen = CartScreen(key: _cartKey);
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
      HomeScreen(
        key: _homeKey,
        initialDrawerData: widget.initialDrawerData,
        onViewAllNewArrival: () {
          // Manually change tab using helper
          _changeTab(2);
          // Then apply specific logic
          // Note: _changeTab resets mode, so we might need a slight delay or specific handling here
          // But for simplicity, we keep your original logic flow manually:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _storeKey.currentState?.switchMode(onSale: false, categoryId: null);
          });
        },
        onViewAllFlashSale: () {
          _changeTab(2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _storeKey.currentState?.switchMode(onSale: true, categoryId: null);
          });
        },
        onViewAllEmulators: () {
          _changeTab(2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            const int emulatorCategoryId = 62;
            _storeKey.currentState?.switchMode(
              onSale: false,
              categoryId: emulatorCategoryId,
            );
          });
        },
      ),
      DiscoverScreen(key: _discoverKey),
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

          // ✅ HISTORY LOGIC
          if (_navigationHistory.length > 1) {
            setState(() {
              // 1. Remove current tab from stack
              _navigationHistory.removeLast();
              // 2. Go to the previous tab (new last item)
              _currentIndex = _navigationHistory.last;
            });
            _refreshTab(_currentIndex);
            return;
          }

          // ✅ EXIT LOGIC (Only runs if history has 1 item, which is Home)
          final now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
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
          onTabChange: (index) => _changeTab(index), // Use helper
          onSearchTap: () => _changeTab(1), // Use helper
          searchController: _searchController,
          showAppBar: _currentIndex != 1,
          drawer: CustomDrawer(
            initialData: widget.initialDrawerData,
            onNavigateToIndex: (index) {
              _changeTab(index); // Use helper
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}