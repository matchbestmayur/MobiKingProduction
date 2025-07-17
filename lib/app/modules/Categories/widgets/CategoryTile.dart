import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Import AppTheme

class CategoryTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const CategoryTile({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90, // Fixed width for each tile in the horizontal list
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), // Slightly rounded corners
          // No shadow or border here, let the parent list manage separation
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8), // Image has slightly smaller radius
              child: Image.network(
                imageUrl,
                width: 80, // Slightly smaller than container width
                height: 80, // Fixed height for image
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.neutralBackground, // Light grey placeholder
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: AppColors.textLight, // Lighter icon
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8), // Space between image and text
            Expanded( // Use Expanded to handle potential long text
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2, // Allow up to 2 lines for category name
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith( // Smaller text for category names
                  fontWeight: FontWeight.w600, // Semi-bold
                  color: AppColors.textDark, // Dark text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}