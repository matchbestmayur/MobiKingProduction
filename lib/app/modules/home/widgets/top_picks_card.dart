import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';
import '../../Product_page/product_page.dart'; // Ensure this path is correct
import 'favorite_toggle_button.dart'; // Re-use the favorite button

class TopPicksCard extends StatelessWidget {
  final ProductModel product;
  final Function(ProductModel)? onTap;
  final String heroTag;

  const TopPicksCard({
    Key? key,
    required this.product,
    this.onTap,
    required this.heroTag,
  }) : super(key: key);

  // Define consistent dimensions for a square appearance
  static const double _cardSize = 130.0; // Overall size of the square card
  static const double _imageSize = 110.0; // Size of the square image area within the card

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasImage = product.images.isNotEmpty && product.images[0].isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: Material(
        color: AppColors.neutralBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (onTap != null) {
              onTap!.call(product);
            } else {
              Get.to(
                    () => ProductPage(
                  product: product,
                  heroTag: heroTag, // Hero tag passed here
                ),
              );
            }
          },
          child: Container(
            width: _cardSize, // Fixed width for the entire card
            height: _cardSize, // Fixed height for the entire card (making it square)
            decoration: BoxDecoration(
              color: AppColors.neutralBackground, // Background color is transparent
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // Padding around the image
                      color: Colors.transparent,
                      child: Hero(
                        tag: heroTag, // Hero tag used here
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8), // Border radius for the image
                          child: Container(
                            height: _imageSize, // Fixed square height for the image area
                            width: _imageSize, // Fixed square width for the image area
                            color: AppColors.neutralBackground, // Placeholder background
                            child: hasImage
                                ? Image.network(
                              product.images[0],
                              fit: BoxFit.fill, // **Changed from BoxFit.fill to BoxFit.cover**
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 30,
                                  color: AppColors.textLight,
                                ),
                              ),
                            )
                                : Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 30,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                      child: Text(
                        product.name,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Favorite Button (Top Right)
                Positioned(
                  top: 10,
                  right: 8,
                  child: FavoriteToggleButton(
                    productId: product.id.toString(),
                    iconSize: 16,
                    padding: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}