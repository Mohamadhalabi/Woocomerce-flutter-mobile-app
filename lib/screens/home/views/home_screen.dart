import 'package:flutter/material.dart';
import '../../../components/home_page_banners/home_page_banner1.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/new_arrival_products.dart';
import 'components/flash_sale.dart';
import 'components/emulators.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  bool get wantKeepAlive => true; // ✅ preserves state when tab is not visible

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
                const OffersCarouselAndCategories(),
                NewArrivalProducts(refreshCounter: refreshCounter),
                const HomePageBanner1(),
                FlashSaleProducts(refreshCounter: refreshCounter),
                EmulatorProducts(refreshCounter: refreshCounter),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
