import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../constants.dart';
import 'package:shop/components/dot_indicators.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedIndex = 0;
  bool isLoading = true;
  Timer? _timer;
  List<Map<String, String>> offers = [];

  @override
  void initState() {
    super.initState();
    _loadLocalSliders();
  }

  void _loadLocalSliders() {
    setState(() {
      offers = [
        {'image': 'assets/sliders/banner-1-renamed.webp', 'link': ''},
        {'image': 'assets/sliders/banner-2.webp', 'link': ''},
      ];
      isLoading = false;
    });
    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (offers.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;

      setState(() {
        _selectedIndex = (_selectedIndex + 1) % offers.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: OffersSkelton());
    if (offers.isEmpty) return const Center(child: Text("No sliders available"));

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 9 / 23;

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: BannerMStyle1(
              key: ValueKey<String>(offers[_selectedIndex]['image']!),
              image: offers[_selectedIndex]['image']!,
              press: () {
                print("Redirecting to: ${offers[_selectedIndex]['link']}");
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              height: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  offers.length,
                      (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DotIndicator(
                      isActive: index == _selectedIndex,
                      activeColor: Colors.white70,
                      inActiveColor: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class BannerMStyle1 extends StatelessWidget {
  const BannerMStyle1({super.key, required this.image, required this.press});

  final String image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 9 / 16;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        width: screenWidth,
        height: bannerHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: press,
            child: Image.asset(
              image,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ),
    );
  }
}