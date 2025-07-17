import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Useful for GetX navigation if you use it in onBack
// import 'package:like_button/like_button.dart'; // Keep if used elsewhere, not strictly needed for Hero

import '../../home/widgets/favorite_toggle_button.dart'; // Your custom favorite button
import '../../../themes/app_theme.dart'; // Assuming AppColors are defined here

class ProductImageBanner extends StatefulWidget {
  final List<String> imageUrls;
  final String? badgeText; // Changed to nullable
  final String productId;
  final VoidCallback? onBack;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final String heroTag;
  final bool showZoomButton; // New: control visibility of zoom button
  final bool showShareButton; // New: control visibility of share button

  const ProductImageBanner({
    super.key,
    required this.imageUrls,
    this.badgeText, // Now nullable
    required this.productId,
    this.onBack,
    this.onFavorite,
    this.isFavorite = false,
    required this.heroTag,
    this.showZoomButton = true, // Default to true as per request
    this.showShareButton = true, // Default to true as per request
  });

  @override
  State<ProductImageBanner> createState() => _ProductImageBannerState();
}

class _ProductImageBannerState extends State<ProductImageBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350, // Slightly increased height for better visual impact
      width: double.infinity,
      child: Stack(
        children: [
          // --- Main Image (Hero Animation & PageView) ---
          Hero(
            tag: widget.heroTag,
            child: PageView.builder(
              itemCount: widget.imageUrls.isEmpty ? 1 : widget.imageUrls.length, // Handle empty imageUrls list
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (_, index) {
                final String imageUrl = widget.imageUrls.isNotEmpty ? widget.imageUrls[index] : '';
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.neutralBackground, // Fallback background color
                    // Ensure borderRadius is consistent if used in parent widget like ClipRRect
                    // or remove it if the parent already clips
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPurple, // Theme color for loader
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 40, color: AppColors.textLight.withOpacity(0.7)),
                              const SizedBox(height: 8),
                              Text('Image Load Error', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textLight.withOpacity(0.7))),
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

          // --- Top Left: Back button ---
          Positioned(
            top: 16, // Consistent top padding
            left: 16, // Consistent left padding
            child: SafeArea( // Ensures buttons are not hidden by notch/status bar
              child: GestureDetector(
                onTap: widget.onBack ?? () => Get.back(), // Use Get.back() for consistency
                child: Container(
                  width: 32, // Fixed size for consistent tap area
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4), // Softer opacity
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),

          // --- Top Right: Favorite button ---
          Positioned(
            top: 16, // Consistent top padding
            right: 16, // Consistent right padding
            child: SafeArea( // Ensures buttons are not hidden by notch/status bar
              child: FavoriteToggleButton(
                productId: widget.productId,
                iconSize: 22, // Slightly larger icon
                padding: 6, // More padding for better visual
                containerOpacity: 0.4, // Softer container background
                onChanged: (isFavorite) {
                  widget.onFavorite?.call();
                },
              ),
            ),
          ),

        /*  // --- Bottom Right: Share button (Floating Icon) ---
          if (widget.showShareButton)
            Positioned(
              bottom: 16, // Distance from bottom
              right: 16, // Distance from right
              child: FloatingActionButton.small(
                heroTag: 'share_button_${widget.productId}', // Unique heroTag
                onPressed: () {
                  // TODO: Implement actual sharing logic (e.g., using share_plus package)
                  Get.snackbar(
                    'Share',
                    'Sharing product: ${widget.imageUrls.first}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.success.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                  debugPrint('Share button tapped');
                },
                backgroundColor: AppColors.primaryPurple.withOpacity(0.8), // Theme-consistent color
                foregroundColor: Colors.white, // Icon color
                elevation: 4, // Subtle shadow
                child: const Icon(Icons.share_rounded, size: 20), // Rounded icon
              ),
            ),

          // --- Bottom Right: Zoom button (Floating Icon) ---
          if (widget.showZoomButton)
            Positioned(
              bottom: 16,
              right: 76, // Positioned to the left of the share button (16 + 56 (FAB size) + 4 padding)
              child: FloatingActionButton.small(
                heroTag: 'zoom_button_${widget.productId}', // Unique heroTag
                onPressed: () {
                  // TODO: Implement image zoom functionality (e.g., navigate to a full-screen image viewer)
                  Get.snackbar(
                    'Zoom',
                    'Zooming into product image',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.info.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                  debugPrint('Zoom button tapped');
                },
                backgroundColor: AppColors.primaryPurple.withOpacity(0.8), // Theme-consistent color
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.zoom_in_map_rounded, size: 20), // Rounded icon
              ),
            ),*/

          // --- Discount Badge (Dynamic Visibility and Styling) ---
          if (widget.badgeText != null && widget.badgeText!.isNotEmpty)
            Positioned(
              top: 16,
              left: 16, // Positioned to the left, slightly below top-left corner
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange, // Use an accent color for badges
                    borderRadius: BorderRadius.circular(6), // Slightly rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10), // More padding
                  child: Text(
                    widget.badgeText!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith( // Use app theme's label style
                      color: AppColors.white,
                      fontWeight: FontWeight.w700, // Make text bold
                    ),
                  ),
                ),
              ),
            ),

          // --- Dots indicator ---
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                    (index) => Container(
                  width: _currentIndex == index ? 10 : 6, // Active dot slightly larger
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3), // Rounded rect for dots
                    color: _currentIndex == index ? AppColors.white : AppColors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}