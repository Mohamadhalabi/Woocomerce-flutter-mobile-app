import 'package:flutter/material.dart';
import '../../../components/home_page_banners/home_page_banner1.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/new_arrival_products.dart';
import 'components/flash_sale.dart';
import 'components/emulators.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white, // optional
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OffersCarouselAndCategories(),
              NewArrivalProducts(),
              HomePageBanner1(),
              FlashSaleProducts(),
              EmulatorProducts(),
            ],
          ),
        ),
      ),
    );
  }
}