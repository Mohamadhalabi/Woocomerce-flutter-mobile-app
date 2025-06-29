import 'package:flutter/material.dart';

import '../constants.dart';

class DotIndicator extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inActiveColor;
  final double size;

  const DotIndicator({
    super.key,
    required this.isActive,
    required this.activeColor,
    required this.inActiveColor,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inActiveColor,
        shape: BoxShape.circle,
      ),
    );
  }
}