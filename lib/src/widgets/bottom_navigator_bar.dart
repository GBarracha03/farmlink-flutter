import 'package:flutter/material.dart';

class BottomNavigatorBarDefault extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavigatorBarDefault({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      backgroundColor: Color(0xFF2A815E),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicío"),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: "Encomendas",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: "Minha Banca"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Gestão"),
      ],
    );
  }
}
