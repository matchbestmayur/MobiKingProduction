import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../home/widgets/favorite_toggle_button.dart';

class ProductImageBanner extends StatefulWidget {
  final List<String> imageUrls;
  final String? badgeText;
  final String productId;
  final VoidCallback? onBack;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final String heroTag;
  final bool showZoomButton;
  final bool showShareButton;

  final double productRating;
  final int reviewCount;

  const ProductImageBanner({
    super.key,
    required this.imageUrls,
    this.badgeText,
    required this.productId,
    this.onBack,
    this.onFavorite,
    this.isFavorite = false,
    required this.heroTag,
    this.showZoomButton = true,
    this.showShareButton = true,
    required this.productRating,
    required this.reviewCount,
  });

  @override
  State<ProductImageBanner> createState() => _ProductImageBannerState();
}

class _ProductImageBannerState extends State<ProductImageBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      width: double.infinity,
      child: Stack(
        children: [
          // Main Image
          Hero(
            tag: widget.heroTag,
            child: PageView.builder(
              itemCount: widget.imageUrls.isEmpty ? 1 : widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (_, index) {
                final imageUrl = widget.imageUrls.isNotEmpty ? widget.imageUrls[index] : '';
                return Container(
                  padding: EdgeInsets.all(40),
                  color: AppColors.white,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.fill,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPurple,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: AppColors.textLight.withOpacity(0.7)),
                          const SizedBox(height: 8),
                          Text(
                            'Image Load Error',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textLight.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : Center(
                    child: Icon(Icons.image_not_supported, size: 60, color: AppColors.textLight.withOpacity(0.7)),
                  ),
                );
              },
            ),
          ),


          // Favorite Button
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: FavoriteToggleButton(
                productId: widget.productId,
                iconSize: 22,
                padding: 6,
                containerOpacity: 0.4,
                onChanged: (isFav) => widget.onFavorite?.call(),
              ),
            ),
          ),

          // Badge (top left)
          if (widget.badgeText != null && widget.badgeText!.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  child: Text(
                    widget.badgeText!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

          // ⭐ Rating + Review Count (bottom left)
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neutralBackground, // Dark background
                borderRadius: BorderRadius.only(topRight: Radius.circular(12),topLeft: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // ⭐ Star icons
                  ...List.generate(5, (index) {
                    double filled = widget.productRating - index;
                    IconData iconData;
                    if (filled >= 1) {
                      iconData = Icons.star;
                    } else if (filled >= 0.5) {
                      iconData = Icons.star_half;
                    } else {
                      iconData = Icons.star_border;
                    }
                    return Icon(iconData, color: Colors.yellow, size: 16);
                  }),
                  const SizedBox(width: 6),

                  // 📊 Rating value
                  Text(
                    widget.productRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 4),

                  // 🗣 Review count
                  Text(
                    '(${widget.reviewCount})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),



          // 🔘 Dots Indicator (bottom right)
          Positioned(
            bottom: 10,
            right: 16,
            child: Row(
              children: List.generate(
                widget.imageUrls.length,
                    (index) => Container(
                  width: _currentIndex == index ? 10 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _currentIndex == index ? AppColors.textDark : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: widget.onBack ?? () => Get.back(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
