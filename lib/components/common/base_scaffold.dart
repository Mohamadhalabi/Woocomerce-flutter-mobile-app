// import 'package:flutter/material.dart';
// import 'drawer.dart';
//
// class BaseScaffold extends StatelessWidget {
//   final Widget body;
//   final int currentIndex;
//   final ValueChanged<int> onTabChange;
//
//   const BaseScaffold({
//     super.key,
//     required this.body,
//     required this.currentIndex,
//     required this.onTabChange,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const CustomDrawer(),
//       body: body,
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: currentIndex,
//         onTap: onTabChange,
//         selectedItemColor: Theme.of(context).primaryColor,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Mağaza"),
//           BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
//           BottomNavigationBarItem(icon: Icon(Icons.store), label: "Kaydedilenler"),
//           BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
//         ],
//       ),
//     );
//   }
// }
