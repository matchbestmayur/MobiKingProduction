import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Keep if you use Google Fonts elsewhere, otherwise can remove
import 'package:mobiking/app/themes/app_theme.dart';

import '../controllers/BottomNavController.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavController navController = Get.find<BottomNavController>();

    // Using your provided navItems structure
    final List<Map<String, dynamic>> navItems = [
      {'icon': 'assets/svg/home.svg', 'label': 'Home'},
      {'icon': 'assets/svg/category.svg', 'label': 'Categories'},
      {'icon': 'assets/svg/order.svg', 'label': 'Orders'},
      {'icon': 'assets/svg/profile.svg', 'label': 'Profile'},
    ];

    // The content height of the bar, excluding bottom safe area
    const double contentHeight = 65.0; // Adjusted for better spacing
    final double bottomSafeAreaPadding = MediaQuery.of(context).padding.bottom;

    return Obx(
          () => Container(
        height: contentHeight + bottomSafeAreaPadding, // Total height including safe area
        decoration: BoxDecoration(
          color: AppColors.white, // White background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // Rounded top corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Subtle shadow
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -4), // Shadow going upwards
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomSafeAreaPadding), // Push content up from system nav bar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Generate the first 4 navigation items
              ...List.generate(navItems.length, (index) {
                final bool isSelected = navController.selectedIndex.value == index;
                final String iconPath = navItems[index]['icon'];
                final String label = navItems[index]['label'];

                // Determine icon and text color based on selection and 'Home' status
                Color iconColor = isSelected
                    ? (label == 'Home' ? Colors.yellow[700]! : AppColors.accentNeon) // Yellow for selected Home, accentNeon for others
                    : AppColors.textLight; // Muted grey for unselected

                Color textColor = isSelected
                    ? AppColors.textDark // Darker text for selected
                    : AppColors.textLight; // Muted grey for unselected

                // Adjusted font weight for selected labels
                FontWeight fontWeight = isSelected ? FontWeight.w700 : FontWeight.w500;

                return Expanded(
                  child: InkWell(
                    onTap: () => navController.changePage(index),
                    highlightColor: Colors.transparent,
                    splashColor: AppColors.accentNeon.withOpacity(0.1), // Slightly less intrusive splash
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: SvgPicture.asset(
                              iconPath,
                              color: iconColor, // CHANGE TO THIS
                              width: 26,
                              height: 26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: fontWeight,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}