/*
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming GetX for navigation or state
import 'dart:math'; // For the random rating demo

import '../../../themes/app_theme.dart'; // Your app's theme colors
import 'app_star_rating.dart'; // Assuming you have this widget
import '../../../data/product_model.dart'; // Used for product structure if needed for context
// Note: This card is for visual grouping, not direct product interaction.
// We don't need cart_controller or favorite_toggle_button for this specific card.

// Define a consistent height for these group cards to match product cards
const double kGroupProductCardOverallHeight = 220.0; // Matches kProductCardOverallHeight

class GroupProductCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String heroTag; // For Hero animations if you navigate to a detail screen
  final VoidCallback? onTap; // Callback when the card is tapped

  // You can add more properties if needed, e.g., description, product count
  // For demonstration, we'll include dummy rating data to mimic product card
  static final Random _random = Random();

  const GroupProductCard({
    Key? key,
    required this.title,
    this.imageUrl,
    required this.heroTag,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final double demoRating = 3.0 + _random.nextDouble() * 2.0;
    final int demoRatingCount = 10 + _random.nextInt(1000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0), // Consistent padding
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10), // Consistent border radius
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap, // Use the provided onTap callback
          child: Container(
            width: 130, // Consistent fixed width for the card
            height: kGroupProductCardOverallHeight, // Apply consistent height
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withOpacity(0.05), // Lighter shadow
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Area (mimics ProductCard)
                Container(
                  padding: const EdgeInsets.all(6), // Reduced padding around the image
                  color: Colors.transparent,
                  child: Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8), // Smaller border radius for the image
                      child: Container(
                        height: 100, // Consistent fixed height for the image area
                        width: double.infinity,
                        color: AppColors.neutralBackground,
                        child: hasImage
                            ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.broken_image, size: 30, color: AppColors.textLight),
                          ),
                        )
                            : Center(
                          child: Icon(Icons.image_not_supported, size: 30, color: AppColors.textLight),
                        ),
                      ),
                    ),
                  ),
                ),
                // Text Content Area (mimics ProductCard)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: textTheme.bodySmall?.copyWith( // Consistent font for title
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2, // Allow 2 lines for group names if needed
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Dummy rating for visual consistency (can be removed if not desired)
                      AppStarRating(
                        rating: demoRating,
                        ratingCount: demoRatingCount,
                        starSize: 10, // Smaller stars
                      ),
                      // Removed price and discount specific to product cards
                    ],
                  ),
                ),
                // Spacer to push content up and provide consistent bottom alignment
                // This replaces the 'Add to Cart' button's space
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/
