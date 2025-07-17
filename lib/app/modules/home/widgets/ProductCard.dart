// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math';

import '../../../controllers/cart_controller.dart';
import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';
import 'app_star_rating.dart';
import 'favorite_toggle_button.dart';

// IMPORTANT: Make sure this import path is correct for your ProductPage
import 'package:mobiking/app/modules/Product_page/product_page.dart';

class ProductCards extends StatelessWidget {
  final ProductModel product;
  final Function(ProductModel)? onTap;
  final String heroTag;

  const ProductCards({
    Key? key,
    required this.product,
    this.onTap,
    required this.heroTag,
  }) : super(key: key);

  static final Random _random = Random();

  Widget _buildQuantitySelectorButton(
      int totalQuantity,
      ProductModel product,
      CartController cartController,
      BuildContext context,
      ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasMultipleVariants = product.variants.length > 1;


    return Container(
      height: 30, // Consistent smaller height for the button
      width: 80, // Consistent smaller width for the button
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(6), // Smaller radius
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space
        children: [
          // Decrement Button
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact(); // Haptic feedback on tap
              if (hasMultipleVariants || totalQuantity > 1) {
                // If multiple variants or quantity > 1, show bottom sheet
                _showVariantBottomSheet(context, product.variants, product);
              } else {
                // If single variant and quantity is 1, remove from cart
                final cartItemsForProduct = cartController.getCartItemsForProduct(productId: product.id);
                if (cartItemsForProduct.isNotEmpty) {
                  final singleVariantName = cartItemsForProduct.keys.first;
                  cartController.removeFromCart(productId: product.id, variantName: singleVariantName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed ${singleVariantName} from cart!'),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4), // Reduced padding
              child: Icon(Icons.remove, color: AppColors.white, size: 16), // Smaller icon size
            ),
          ),
          // Animated Quantity Text
          _AnimatedQuantityText(
            quantity: totalQuantity,
            textStyle: textTheme.labelSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          // Increment Button
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact(); // Haptic feedback on tap
              if (hasMultipleVariants) {
                // If multiple variants, show bottom sheet
                _showVariantBottomSheet(context, product.variants, product);
              } else {
                // If single variant, add directly to cart
                final singleVariant = product.variants.entries.first;
                cartController.addToCart(productId: product.id, variantName: singleVariant.key);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${singleVariant.key} to cart!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4), // Reduced padding
              child: Icon(Icons.add, color: AppColors.white, size: 16), // Smaller icon size
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final cartController = Get.find<CartController>();

    final hasImage = product.images.isNotEmpty && product.images[0].isNotEmpty;

    // --- UPDATED PRICE CALCULATION LOGIC BASED ON YOUR REQUIREMENTS ---
    final int originalPrice;
    final int sellingPrice; // This will effectively be your discounted/final price



    if (product.sellingPrice.length >= 2) {
      // If there are at least two prices in sellingPrice:
      // Original price should ideally come from regularPrice if available,
      // otherwise, it falls back to the second-to-last sellingPrice.
      originalPrice = product.regularPrice ?? product.sellingPrice[product.sellingPrice.length - 2].price.toInt();
      // Selling price is always the last in the sellingPrice list.
      sellingPrice = product.sellingPrice.last.price.toInt();
    } else if (product.sellingPrice.length == 1) {
      // If there's only one price in sellingPrice:
      // The original price should still try to come from regularPrice if available.
      // If regularPrice is null, then the single sellingPrice is the original.
      originalPrice = product.regularPrice ?? product.sellingPrice.first.price.toInt();
      // The selling price is that single price.
      sellingPrice = product.sellingPrice.first.price.toInt();
    } else {
      // If the sellingPrice list is empty:
      // The original price falls back to regularPrice if available, otherwise 0.
      originalPrice = product.regularPrice ?? 0;
      // Selling price defaults to 0.
      sellingPrice = 0;
    }

    // Calculate discount percentage
    int discountPercent = 0;
    if (originalPrice > 0 && sellingPrice < originalPrice) {
      discountPercent = (((originalPrice - sellingPrice) / originalPrice) * 100).round();
    }

    final double demoRating = 3.0 + _random.nextDouble() * 2.0;
    final int demoRatingCount = 10 + _random.nextInt(1000);


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0), // Reduced padding between cards
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10), // Smaller border radius for card
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (onTap != null) {
              onTap!.call(product);
            } else {
              Get.to(
                    () => ProductPage(
                  product: product,
                  heroTag: heroTag,
                ),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 300),
              );
            }
          },
          child: Container(
            width: 130, // Smaller fixed width for the card
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // Reduced padding around the image
                      color: Colors.transparent,
                      child: Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8), // Smaller border radius for the image
                          child: Container(
                            height: 100, // Smaller fixed height for the image area
                            width: double.infinity,
                            color: AppColors.neutralBackground,
                            child: hasImage
                                ? Image.network(
                              product.images[0],
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(Icons.broken_image, size: 30, color: AppColors.textLight), // Smaller icon
                              ),
                            )
                                : Center(
                              child: Icon(Icons.image_not_supported, size: 30, color: AppColors.textLight), // Smaller icon
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            product.name,
                            style: textTheme.bodySmall?.copyWith( // Smaller font for product name
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1, // Stick to one line for a cleaner look
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          AppStarRating(
                            rating: demoRating,
                            ratingCount: demoRatingCount,
                            starSize: 10, // Smaller stars
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "₹$sellingPrice",
                                style: textTheme.bodyMedium?.copyWith( // Smaller font for selling price
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  fontSize: 14, // Explicitly set font size
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (originalPrice > 0 && sellingPrice < originalPrice)
                                Text(
                                  "₹$originalPrice",
                                  style: textTheme.labelSmall?.copyWith( // Smaller font
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textLight,
                                    fontSize: 9, // Explicitly set font size
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (discountPercent > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), // Reduced padding
                              decoration: BoxDecoration(
                                color: AppColors.discountGreen,
                                borderRadius: BorderRadius.circular(3), // Smaller radius
                              ),
                              child: Text(
                                "$discountPercent% OFF",
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9, // Smaller font size
                                ),
                              ),
                            ),
                        ],
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
                    iconSize: 16, // Smaller icon
                    padding: 4, // Reduced padding
                  ),
                ),
                // ADD/Quantity Button (Bottom Right)
                Positioned(
                  bottom: 75,
                  right: 2,
                  child: SizedBox(
                    width: 80,
                    height: 30,
                    child: Obx(() {
                      int totalProductQuantityInCart = 0;

                      for (var variantEntry in product.variants.entries) {
                        totalProductQuantityInCart += cartController.getVariantQuantity(
                          productId: product.id,
                          variantName: variantEntry.key,
                        );
                      }

                      final int availableVariantCount = product.variants.entries
                          .where((entry) => entry.value > 0)
                          .length;

                      if (totalProductQuantityInCart > 0) {
                        return SizedBox(
                          width: 80,
                          height: 30,
                          child: _buildQuantitySelectorButton(
                            totalProductQuantityInCart,
                            product,
                            cartController,
                            context,
                          ),
                        );
                      } else {
                        if (availableVariantCount > 1) {
                          return SizedBox(
                            width: 80,
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () {
                                _showVariantBottomSheet(context, product.variants, product);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.success,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(color: AppColors.success, width: 1),
                                ),
                                elevation: 0,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: Size.zero,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ADD',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$availableVariantCount options',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (availableVariantCount == 1) {
                          return SizedBox(
                            width: 80,
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () {
                                final singleVariant = product.variants.entries.firstWhere(
                                        (element) => element.value > 0);
                                cartController.addToCart(
                                  productId: product.id,
                                  variantName: singleVariant.key,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${singleVariant.key} to cart!'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: Size.zero,
                              ),
                              child: Center(
                                child: Text(
                                  'ADD',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return SizedBox(
                            width: 80,
                            height: 30,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.neutralBackground,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Sold Out',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    }),
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

class _AnimatedQuantityText extends StatelessWidget {
  final int quantity;
  final TextStyle? textStyle;

  const _AnimatedQuantityText({
    Key? key,
    required this.quantity,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use TweenAnimationBuilder for the pop effect
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0), // Start and end at 1.0 normally
      duration: const Duration(milliseconds: 200), // Smooth pop duration
      key: ValueKey<int>(quantity), // Key changes when quantity changes to trigger animation
      builder: (BuildContext context, double scale, Widget? child) {
        // When quantity changes, the key changes, and the animation is triggered.
        // We make it pop by scaling to 1.2 and back to 1.0
        final curvedScale = Curves.easeOutBack.transform(scale); // Apply a curve for more dynamic feel

        return Transform.scale(
          scale: scale == 1.0 ? 1.0 : (1.0 + (curvedScale * 0.2)), // Scale up to 1.2, then back to 1.0
          child: Text(
            '$quantity',
            style: textStyle,
          ),
        );
      },
      onEnd: () {
        // Optional: Perform any action when the animation ends
      },
    );
  }
}



// These helper functions remain outside as they are general utilities.
void _showVariantBottomSheet(BuildContext context, Map<String, int> variantsMap, ProductModel product) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final CartController cartController = Get.find<CartController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      final List<MapEntry<String, int>> variantEntries = variantsMap.entries.toList();

      final Map<String, RxBool> isAddingToCart = {};
      final Map<String, RxBool> isRemovingFromCart = {};

      for (var entry in variantEntries) {
        isAddingToCart[entry.key] = false.obs;
        isRemovingFromCart[entry.key] = false.obs;
      }

      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                Text(
                  'Select a Variant',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: variantEntries.length,
                    itemBuilder: (context, index) {
                      final entry = variantEntries[index];
                      final variantName = entry.key;
                      final variantStock = entry.value;

                      final bool isOutOfStock = variantStock <= 0;

                      final String variantImageUrl =
                      product.images.isNotEmpty ? product.images[0] : 'https://placehold.co/50x50/cccccc/ffffff?text=No+Img';

                      return Card(
                        color: AppColors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.neutralBackground, width: 1)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  color: AppColors.neutralBackground,
                                  child: isOutOfStock
                                      ? Center(
                                    child: Text(
                                      'Sold Out',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                      : Image.network(
                                    variantImageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: AppColors.success,
                                          strokeWidth: 2.0,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, color: AppColors.textLight),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variantName,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: isOutOfStock ? AppColors.textLight : AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isOutOfStock)
                                      Text(
                                        'Out of Stock',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isOutOfStock)
                                Obx(() {
                                  final currentVariantQuantity = cartController.getVariantQuantity(productId: product.id, variantName: variantName);
                                  final bool adding = isAddingToCart[variantName]?.value ?? false;
                                  final bool removing = isRemovingFromCart[variantName]?.value ?? false;

                                  if (currentVariantQuantity > 0) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: removing ? null : () async {
                                              isRemovingFromCart[variantName]?.value = true;
                                              await Future.delayed(const Duration(milliseconds: 300));
                                              cartController.removeFromCart(productId: product.id, variantName: variantName);
                                              isRemovingFromCart[variantName]?.value = false;
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: removing
                                                  ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.white,
                                                ),
                                              )
                                                  : Icon(Icons.remove, color: AppColors.white, size: 16),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$currentVariantQuantity',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: adding ? null : () async {
                                              isAddingToCart[variantName]?.value = true;
                                              await Future.delayed(const Duration(milliseconds: 300));
                                              cartController.addToCart(productId: product.id, variantName: variantName);
                                              isAddingToCart[variantName]?.value = false;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Added $variantName to cart!'),
                                                  backgroundColor: AppColors.success,
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(milliseconds: 700),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: adding
                                                  ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.white,
                                                ),
                                              )
                                                  : Icon(Icons.add, color: AppColors.white, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return ElevatedButton(
                                      onPressed: adding ? null : () async {
                                        isAddingToCart[variantName]?.value = true;
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        cartController.addToCart(productId: product.id, variantName: variantName);
                                        isAddingToCart[variantName]?.value = false;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Added $variantName to cart!'),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(milliseconds: 700),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        minimumSize: Size.zero,
                                      ),
                                      child: adding
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                          : Text(
                                        'ADD',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }
                                }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

}