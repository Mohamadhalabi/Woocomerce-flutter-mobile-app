// lib/screens/home/views/components/mobile_hero_carousel.dart
//
// The app's own slider, fed by the "mobile-hero" slider in the admin.
// Square by default to match 1080x1080 slide images; the website keeps its
// wide slider untouched.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../repositories/home_repository.dart';

class MobileHeroCarousel extends StatefulWidget {
  const MobileHeroCarousel({
    super.key,
    required this.slides,
    required this.onSlideTap,
    this.aspectRatio = 1, // 1 = 1080x1080. Use 4 / 5 for 1080x1350 images.
  });

  final List<HomeSlide> slides;
  final void Function(HomeSlide slide) onSlideTap;
  final double aspectRatio;

  @override
  State<MobileHeroCarousel> createState() => _MobileHeroCarouselState();
}

class _MobileHeroCarouselState extends State<MobileHeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant MobileHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A refresh can return fewer slides than before.
    if (_index >= widget.slides.length) _index = 0;
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Restarted on every page change, so a manual swipe gets the full
  /// interval before the slider moves on by itself.
  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.slides.length < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;

      _controller.animateToPage(
        (_index + 1) % widget.slides.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    final active = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.slides.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _startAutoPlay();
                },
                itemBuilder: (context, i) {
                  final slide = widget.slides[i];

                  return GestureDetector(
                    onTap: () => widget.onSlideTap(slide),
                    child: CachedNetworkImage(
                      imageUrl: slide.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.slides.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.slides.length, (i) {
                final selected = i == _index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: selected ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? active : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}