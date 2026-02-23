import 'package:flutter/material.dart';
import 'package:projeto/src/orders/order_menu.dart';
import 'package:projeto/src/store/advertisement_menu.dart';
import '../home/home_menu.dart';
import '../manager/gestao_menu.dart';

class NavigationHelper {
  static void onItemTapped(BuildContext context, int index, String userId) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeMenu(userId: userId)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrdersMenu(userId: userId)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdvertisementList(userId: userId),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GestaoMenu(userId: userId)),
        );
        break;
    }
  }
}
