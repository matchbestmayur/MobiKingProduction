import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/product_controller.dart';

import '../controllers/Home_controller.dart';
import '../controllers/sub_category_controller.dart';
import '../controllers/tab_controller_getx.dart';
import '../data/Home_model.dart';
import '../modules/home/widgets/_buildSectionView.dart';
import '../themes/app_theme.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/Home_controller.dart';
import '../controllers/sub_category_controller.dart';
import '../controllers/tab_controller_getx.dart';
import '../data/Home_model.dart';
import '../modules/home/widgets/_buildSectionView.dart';
import '../themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/Home_controller.dart';
import '../controllers/tab_controller_getx.dart';
import '../data/Home_model.dart';
import '../themes/app_theme.dart';

class CustomTabBarSection extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();
  final TabControllerGetX tabControllerGetX = Get.find<TabControllerGetX>();

  CustomTabBarSection({super.key});

  String htmlUnescape(String input) {
    return input
        .replaceAll(r'\u003C', '<')
        .replaceAll(r'\u003E', '>')
        .replaceAll(r'\u0022', '"')
        .replaceAll(r'\u0027', "'")
        .replaceAll(r'\\', '');
  }

  Widget _buildTabItem({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color iconAndTextColor,
    required TextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 22,
            width: 22,
            child: Builder(
              builder: (context) {
                try {
                  final decodedSvg = htmlUnescape(icon);
                  return SvgPicture.string(decodedSvg, color: iconAndTextColor);
                } catch (e) {
                  return Icon(Icons.broken_image, size: 20, color: iconAndTextColor);
                }
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: iconAndTextColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: iconAndTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final HomeLayoutModel? homeLayout = homeController.homeData.value;
      final List<CategoryModel> categories = homeLayout?.categories ?? [];

      if (homeController.isLoading.value || categories.isEmpty) {
        return const SizedBox(
          height: 70,
          child: Center(child: CircularProgressIndicator(color: AppColors.white)),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(categories.length, (index) {
              final category = categories[index];
              final isSelected = tabControllerGetX.selectedIndex.value == index;
              final theme = category.theme ?? 'dark';
              final Color tabColor = theme == 'light' ? Colors.white : Colors.black;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildTabItem(
                  icon: category.icon ?? '',
                  label: category.name,
                  isSelected: isSelected,
                  onTap: () => tabControllerGetX.updateIndex(index),
                  iconAndTextColor: tabColor,
                  textTheme: textTheme,
                ),
              );
            }),
          ),
        ),
      );
    });
  }
}

class CustomTabBarViewSection extends StatelessWidget {
  final TabControllerGetX controller = Get.find<TabControllerGetX>();
  final HomeController homeController = Get.find<HomeController>();
  final SubCategoryController subCategoryController = Get.find<SubCategoryController>();
  final ProductController productController = Get.find<ProductController>();

  CustomTabBarViewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final HomeLayoutModel? homeLayout = homeController.homeData.value;
      final List<CategoryModel> categories = homeLayout?.categories ?? [];
      final selectedIndex = controller.selectedIndex.value;

      if (homeController.isLoading.value ||
          categories.isEmpty ||
          selectedIndex < 0 ||
          selectedIndex >= categories.length) {
        return Container(
          height: 300,
          color: AppColors.neutralBackground,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.accentNeon),
          ),
        );
      }

      final selectedCategory = categories[selectedIndex];
      final allGroups = homeLayout?.groups ?? [];

      final updatedGroups = allGroups.where((group) {
        return group.products.any((product) =>
        product.categoryId != null && product.categoryId == selectedCategory.id);
      }).toList();

      final String bannerImageUrlToUse = selectedCategory.lowerBanner ?? '';

      return buildSectionView(
        productController: productController,
        index: selectedIndex,
        groups: updatedGroups,
        bannerImageUrl: bannerImageUrlToUse,
        categoryGridItems: subCategoryController.subCategories,
        subCategories: subCategoryController.subCategories,
      );
    });
  }
}