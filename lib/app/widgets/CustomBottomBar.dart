import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/themes/app_theme.dart';

import '../controllers/BottomNavController.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavController navController = Get.find<BottomNavController>();

    final List<Map<String, dynamic>> navItems = [
      {'icon': 'assets/svg/home.svg', 'label': 'Home'},
      {'icon': 'assets/svg/category.svg', 'label': 'Categories'},
      {'icon': 'assets/svg/profile.svg', 'label': 'Profile'},
    ];

    const double contentHeight = 65.0;
    final double bottomSafeAreaPadding = MediaQuery.of(context).padding.bottom;

    return Obx(
          () => Container(
        height: contentHeight + bottomSafeAreaPadding,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomSafeAreaPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final bool isSelected = navController.selectedIndex.value == index;
              final String iconPath = navItems[index]['icon'];
              final String label = navItems[index]['label'];

              Color iconColor = isSelected
                  ? (label == 'Home' ? Colors.yellow[700]! : AppColors.accentNeon)
                  : AppColors.textLight;

              Color textColor = isSelected ? AppColors.textDark : AppColors.textLight;
              FontWeight fontWeight = isSelected ? FontWeight.w700 : FontWeight.w500;

              return Expanded(
                child: InkWell(
                  onTap: () => navController.changeTabIndex(index), // ✅ Correct method call
                  highlightColor: Colors.transparent,
                  splashColor: AppColors.accentNeon.withOpacity(0.1),
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
                            color: iconColor,
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
          ),
        ),
      ),
    );
  }
}
