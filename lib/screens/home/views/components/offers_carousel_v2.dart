// lib/screens/home/views/components/offers_carousel_v2.dart
//
// Same carousel as the original, fed by the slides from GET /home instead of
// bundled assets.
//
// SIZING NOTE: the original sized its outer SizedBox at screenWidth * 9/23
// while BannerMStyle1 rendered at 9/16 — the inner image was taller than its
// container, so the bottom got clipped. Both use 9/23 here, which is why this
// version isn't cut off.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../components/dot_indicators.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../repositories/home_repository.dart';

class OffersCarouselV2 extends StatefulWidget {
  const OffersCarouselV2({
    super.key,
    required this.slides,
    this.onSlideTap,
    this.isLoading = false,
  });

  final List<HomeSlide> slides;

  /// Receives the slide's `link`. Currently every slide comes back with
  /// link: null from the API — nothing has been set in the admin yet.
  final void Function(HomeSlide slide)? onSlideTap;

  final bool isLoading;

  @override
  State<OffersCarouselV2> createState() => _OffersCarouselV2State();
}

class _OffersCarouselV2State extends State<OffersCarouselV2> {
  int _selectedIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(OffersCarouselV2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Slides arrive after the first build, so the timer starts empty.
    if (oldWidget.slides.length != widget.slides.length) {
      _selectedIndex = 0;
      _timer?.cancel();
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    if (widget.slides.length < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % widget.slides.length;
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
    if (widget.isLoading) return const Center(child: OffersSkelton());
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 9 / 23;

    final slide = widget.slides[_selectedIndex];

    return SizedBox(
      // Height is reserved so the page doesn't jump as slides swap. The dots
      // sit INSIDE this box rather than below it — stacked underneath they
      // added their own height and left a visible gap under the slider.
      height: bannerHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _Banner(
              key: ValueKey<String>(slide.image),
              slide: slide,
              height: bannerHeight,
              press: () => widget.onSlideTap?.call(slide),
            ),
          ),
          if (widget.slides.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                height: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.slides.length,
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
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.slide,
    required this.height,
    required this.press,
  });

  final HomeSlide slide;
  final double height;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: press,
          child: Image.network(
            slide.image,
            fit: BoxFit.fitWidth,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(color: Colors.grey.shade200),
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}