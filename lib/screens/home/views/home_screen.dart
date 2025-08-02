import 'package:flutter/material.dart';
import '../../../components/home_page_banners/home_page_banner1.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/new_arrival_products.dart';
import 'components/flash_sale.dart';
import 'components/emulators.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDrawerData;
  final VoidCallback? onViewAllNewArrival;
  final VoidCallback? onViewAllFlashSale;
  final VoidCallback? onViewAllEmulators;

  const HomeScreen({
    super.key,
    this.initialDrawerData,
    this.onViewAllNewArrival,
    this.onViewAllFlashSale,
    this.onViewAllEmulators,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  int refreshCounter = 0;

  void refresh() {
    setState(() {
      refreshCounter++;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OffersCarouselAndCategories(
                  initialDrawerData: widget.initialDrawerData,
                ),
                NewArrivalProducts(
                  refreshCounter: refreshCounter,
                  onViewAll: widget.onViewAllNewArrival ?? () {},
                ),
                const HomePageBanner1(),
                FlashSaleProducts(
                  refreshCounter: refreshCounter,
                  onViewAll: widget.onViewAllFlashSale ?? () {},
                ),
                EmulatorProducts(
                  refreshCounter: refreshCounter,
                  onViewAll: widget.onViewAllEmulators ?? () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}