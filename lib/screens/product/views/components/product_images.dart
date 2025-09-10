import 'package:flutter/material.dart';
import '/components/network_image_with_loader.dart';
import '../../../../constants.dart';
import 'image_gallery_modal.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductImages extends StatefulWidget {
  const ProductImages({
    super.key,
    required this.images,
    this.isBestSeller = false,
  });

  final List<String> images;
  final bool isBestSeller;

  @override
  State<ProductImages> createState() => _ProductImagesState();
}

class _ProductImagesState extends State<ProductImages> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    _controller = PageController(viewportFraction: 1, initialPage: _currentPage);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openImageModal(int initialIndex) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: ImageGalleryModal(
            images: widget.images,
            initialIndex: initialIndex,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Let the widget size itself within available width; keep a smaller square inside.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        // shrink main square to 85% of width to “feel” smaller without external constraints
        final double square = maxW * 0.85;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SizedBox(
                width: square,
                height: square,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (pageNum) => setState(() => _currentPage = pageNum),
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(12.0), // was 20; smaller now
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(defaultBorderRadious * 2),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(defaultBorderRadious * 2),
                        ),
                        child: GestureDetector(
                          onTap: () => _openImageModal(index),
                          child: Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              NetworkImageWithLoader(widget.images[index]),
                              if (widget.isBestSeller)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.bestSeller,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 16),
                child: SizedBox(
                  height: 60, // a bit smaller
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      final isActive = index == _currentPage;
                      return GestureDetector(
                        onTap: () {
                          _controller.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isActive ? blueColor : Colors.grey.shade300,
                              width: isActive ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              widget.images[index],
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
