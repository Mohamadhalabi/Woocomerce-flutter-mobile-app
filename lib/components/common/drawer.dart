import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/constants.dart';

class CustomEndDrawer extends StatelessWidget {
  const CustomEndDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: blueColor),
            child: Text(
              localizations.drawerHeader,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          // You can add more items here if needed
        ],
      ),
    );
  }
}
