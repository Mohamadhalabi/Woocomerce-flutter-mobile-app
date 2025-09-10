import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../skelton.dart';

// ===================== SKELETONS =====================
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    BoxDecoration cardDec() => BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      boxShadow: [
        BoxShadow(
          color: theme.brightness == Brightness.dark
              ? Colors.black.withOpacity(0.3)
              : Colors.black12,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header skeleton
          Container(
            decoration: cardDec(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                _SkeletonCircle(size: 52),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 160, height: 14, radius: 6),
                      SizedBox(height: 8),
                      _SkeletonBox(width: 120, height: 12, radius: 6),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                _SkeletonCircle(size: 28),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section title
          const _SkeletonSectionTitle(),
          // A couple of tiles
          _SkeletonTile(decoration: cardDec()),
          _SkeletonTile(decoration: cardDec()),
          const SizedBox(height: 8),

          // Section title
          const _SkeletonSectionTitle(),
          // Currency row
          _SkeletonTile(
            decoration: cardDec(),
            hasTrailingShort: true,
          ),
          // Dark mode switch
          _SkeletonTile(
            decoration: cardDec(),
            hasTrailingSwitch: true,
          ),

          const SizedBox(height: 8),
          const _SkeletonSectionTitle(),
          _SkeletonTile(decoration: cardDec()),
          _SkeletonTile(decoration: cardDec()),
        ],
      ),
    );
  }
}

class _SkeletonSectionTitle extends StatelessWidget {
  const _SkeletonSectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: _SkeletonBox(width: 120, height: 14, radius: 6),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  final BoxDecoration decoration;
  final bool hasTrailingShort;
  final bool hasTrailingSwitch;

  const _SkeletonTile({
    super.key,
    required this.decoration,
    this.hasTrailingShort = false,
    this.hasTrailingSwitch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const _SkeletonCircle(size: 36),
          const SizedBox(width: 12),
          const Expanded(
            child: _SkeletonBox(width: double.infinity, height: 14, radius: 6),
          ),
          const SizedBox(width: 12),
          if (hasTrailingShort) const _SkeletonBox(width: 42, height: 16, radius: 6),
          if (hasTrailingSwitch) const _SkeletonSwitch(width: 44, height: 24),
          if (!hasTrailingShort && !hasTrailingSwitch)
            const Icon(Icons.chevron_right, color: Colors.transparent, size: 16),
        ],
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;
  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE6E6E6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width == double.infinity ? double.infinity : width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _SkeletonSwitch extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonSwitch({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// Lightweight shimmer without extra packages
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFEAEAEA);
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A4A4A)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            final dx = rect.width * _ctrl.value;
            return LinearGradient(
              begin: Alignment(-1.0 + _ctrl.value * 2, 0),
              end: Alignment(1.0 + _ctrl.value * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
              transform: GradientTranslation(dx, 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Helper to move gradient
class GradientTranslation extends GradientTransform {
  final double dx, dy;
  const GradientTranslation(this.dx, this.dy);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(dx, dy);
  }
}
