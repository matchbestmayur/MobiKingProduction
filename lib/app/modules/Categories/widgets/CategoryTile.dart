import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Import AppTheme

class CategoryTile extends StatelessWidget {
  final String title;
  final String? imageUrl; // Made nullable to handle absent URLs
  final VoidCallback onTap;

  const CategoryTile({
    Key? key,
    required this.title,
    this.imageUrl, // No longer required
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
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8), // Image has slightly smaller radius
              child: _buildImageWidget(),
            ),
            const SizedBox(height: 8), // Space between image and text
            Expanded( // Use Expanded to handle potential long text
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2, // Allow up to 2 lines for category name
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Check if imageUrl is null or empty
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackWidget();
    }

    return Image.network(
      imageUrl!,
      width: 80, // Slightly smaller than container width
      height: 80, // Fixed height for image
      fit: BoxFit.fill,
      errorBuilder: (context, error, stackTrace) => _buildFallbackWidget(),
    );
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.neutralBackground, // Light grey placeholder
      child: Icon(
        Icons.category_rounded, // More appropriate icon for categories
        color: AppColors.textLight, // Lighter icon
        size: 30,
      ),
    );
  }
}
