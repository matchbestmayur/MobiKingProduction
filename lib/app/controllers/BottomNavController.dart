// In your BottomNavController
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobiking/app/controllers/system_ui_controller.dart';


import '../modules/Categories/Categories_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/search/SearchPage.dart';

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;

  // Remove OrdersScreen from this list
  final List<Widget> pages = [
     HomeScreen(),
     CategorySectionScreen(),
    // Remove: const OrdersScreen(), // <-- Remove this line
    const ProfileScreen(),
  ];

  void changeTabIndex(int index) {
    // Update index mapping since we removed orders tab
    selectedIndex.value = index;

    // Update your SystemUI logic if needed
    final SystemUIController systemUiController = Get.find<SystemUIController>();

    switch (index) {
      case 0: // Home
        systemUiController.setHomeStyle();
        break;
      case 1: // Categories
        systemUiController.setCategoryStyle();
        break;
      case 2: // Search
        systemUiController.setSearchStyle();
        break;
      case 3: // Profile (was index 4, now index 3)
        systemUiController.setProfileStyle();
        break;
    }
  }
}
