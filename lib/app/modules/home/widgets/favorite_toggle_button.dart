import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:like_button/like_button.dart';

import '../../../controllers/wishlist_controller.dart';
import '../../../services/Sound_Service.dart';
import '../../../themes/app_theme.dart';

class FavoriteToggleButton extends StatelessWidget {
  final String productId;
  final double iconSize;
  final double padding;
  final double containerOpacity;
  final Function(bool isFavorite)? onChanged;

  const FavoriteToggleButton({
    Key? key,
    required this.productId,
    this.iconSize = 18,
    this.padding = 4,
    this.containerOpacity = 0.8,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WishlistController wishlistController = Get.find<WishlistController>();
    final SoundService soundService = Get.find<SoundService>();

    return Obx(() {
      final bool isFavorite = wishlistController.wishlist.any((p) => p.id == productId);

      return LikeButton(
        size: iconSize + padding * 2,
        isLiked: isFavorite,
        likeBuilder: (bool isLiked) {
          return Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(containerOpacity),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.danger : AppColors.textMedium,
              size: iconSize,
            ),
          );
        },
        circleColor: const CircleColor(start: Colors.redAccent, end: Colors.red),
        bubblesColor: const BubblesColor(
          dotPrimaryColor: Colors.redAccent,
          dotSecondaryColor: Colors.red,
        ),
        onTap: (bool isLiked) async {
          soundService.playPopSound();

          if (isLiked) {
            wishlistController.removeFromWishlist(productId);
            Get.snackbar(
              'Wishlist',
              'Removed from wishlist!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.textDark.withOpacity(0.8),
              colorText: AppColors.white,
              duration: const Duration(seconds: 1),
            );
          } else {
            wishlistController.addToWishlist(productId);
            Get.snackbar(
              'Wishlist',
              'Added to wishlist!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.textDark.withOpacity(0.8),
              colorText: AppColors.white,
              duration: const Duration(seconds: 1),
            );
          }

          onChanged?.call(!isLiked);
          return !isLiked;
        },
      );
    });
  }
}
