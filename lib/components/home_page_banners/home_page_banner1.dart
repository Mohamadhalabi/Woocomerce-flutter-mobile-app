import 'package:flutter/material.dart';

class HomePageBanner1 extends StatelessWidget {
  const HomePageBanner1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/emulator-1.webp',
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
}