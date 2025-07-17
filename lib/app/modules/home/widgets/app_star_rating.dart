// lib/widgets/app_star_rating.dart
import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class AppStarRating extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final double starSize; // Added for flexibility

  const AppStarRating({
    Key? key,
    required this.rating,
    required this.ratingCount,
    this.starSize = 14, // Default size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (ratingCount == 0) {
      return const SizedBox.shrink(); // Don't show anything if no ratings
    }

    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star_rounded, color: AppColors.ratingGold, size: starSize));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(Icon(Icons.star_half_rounded, color: AppColors.ratingGold, size: starSize));
      } else {
        stars.add(Icon(Icons.star_border_rounded, color: AppColors.ratingGold.withOpacity(0.5), size: starSize));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...stars,
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
        Text(
          ' ($ratingCount)',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}