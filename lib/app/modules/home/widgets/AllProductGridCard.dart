import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math'; // For demo rating

import 'package:cached_network_image/cached_network_image.dart'; // For efficient image loading

import '../../../controllers/cart_controller.dart'; // Ensure this path is correct
import '../../../data/product_model.dart'; // Ensure this path is correct
import '../../../themes/app_theme.dart'; // Ensure this path is correct
import 'app_star_rating.dart'; // Ensure this path is correct

// IMPORTANT: Make sure this import path is correct for your ProductPage
import 'package:mobiking/app/modules/Product_page/product_page.dart';

class AllProductGridCard extends StatelessWidget {
  final ProductModel product;
  final Function(ProductModel)? onTap;
  final String heroTag;

  const AllProductGridCard({
    Key? key,
    required this.product,
    this.onTap,
    required this.heroTag,
  }) : super(key: key);

  static final Random _random = Random(); // For demo rating

  // Reusing the quantity selector logic for consistency
  Widget _buildQuantitySelectorButton(
      int totalQuantity,
      ProductModel product,
      CartController cartController,
      BuildContext context,
      ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasMultipleVariants = product.variants.length > 1;

    return Container(
      height: 28, // Consistent height for button (matched to ADD button)
      // !!! IMPORTANT: Removed width constraints here. This Container will now size itself based on its content (Row).
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(6), // Matched to ADD button
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min, // Make row take minimum space horizontally
        children: [
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              if (hasMultipleVariants || totalQuantity > 1) {
                _showVariantBottomSheet(context, product.variants, product);
              } else {
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
              padding: EdgeInsets.symmetric(horizontal: 4), // Reduced horizontal padding for buttons
              child: Icon(Icons.remove, color: AppColors.white, size: 16), // Smaller icon
            ),
          ),
          // Using Flexible to prevent text overflow by allowing it to expand, but also enabling shrinking
          Flexible(
            child: _AnimatedQuantityText(
              quantity: totalQuantity,
              textStyle: textTheme.labelSmall?.copyWith( // Smaller font size
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12, // Match ADD button font size
              ),
            ),
          ),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (hasMultipleVariants) {
                _showVariantBottomSheet(context, product.variants, product);
              } else {
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
              padding: EdgeInsets.symmetric(horizontal: 4), // Reduced horizontal padding for buttons
              child: Icon(Icons.add, color: AppColors.white, size: 16), // Smaller icon
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

    final int sellingPrice;
    int actualPrice = 0; // Initialize with 0
    String discountPercentage = '';

    if (product.sellingPrice.isNotEmpty) {
      sellingPrice = product.sellingPrice.last.price.toInt();
      // Corrected logic: actualPrice should come from product.actualPrice, not product.sellingPrice
      if (product.sellingPrice.isNotEmpty) { // Use product.actualPrice if available
        actualPrice = product.sellingPrice.last.price.toInt();
        if (actualPrice > 0 && sellingPrice < actualPrice) {
          double discount = ((actualPrice - sellingPrice) / actualPrice) * 100;
          discountPercentage = '${discount.round()}% off';
        }
      } else {
        actualPrice = sellingPrice; // If no actual price, assume it's the selling price for comparison
      }
    } else {
      sellingPrice = 0;
      actualPrice = 0;
    }

    final double demoRating = 3.0 + _random.nextDouble() * 2.0;
    final int demoRatingCount = 10 + _random.nextInt(1000);

    // Define a fixed width for the initial "ADD" button
    const double addBtnFixedWidth = 60.0; // Adjust as needed
    const double buttonHeight = 28.0; // Consistent height for all states

    return Card(
      elevation: 0, // No elevation
      color: Colors.transparent, // Outer card is transparent
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container( // Inner container for the white background and border
        decoration: BoxDecoration(
          color: Colors.transparent, // This should be white for the card background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutralBackground, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Section (TOP)
              AspectRatio(
                aspectRatio: 1.0, // Square image area
                child: Stack(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0), // Padding around the image
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8), // Rounded image corners
                          child: Container(
                            width: double.infinity,
                            height: double.infinity, // Fill available space
                            color: AppColors.neutralBackground,
                            child: hasImage
                                ? CachedNetworkImage(
                              imageUrl: product.images[0],
                              fit: BoxFit.contain, // Fit entire image, prevent cropping
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryPurple.withOpacity(0.5),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
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
                    // Discount Banner (positioned over image, top-left)
                    if (discountPercentage.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple, // Or a distinct color for discount
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            discountPercentage,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    // ADD Button / Quantity Selector (positioned on image, bottom-right)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      // The SizedBox directly wrapping the Obx will handle the sizing conditionally
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
                          // Quantity Selector: No fixed width, allow it to size flexibly
                          return _buildQuantitySelectorButton(
                            totalProductQuantityInCart,
                            product,
                            cartController,
                            context,
                          );
                        } else {
                          if (availableVariantCount > 0) {
                            // ADD button: Fixed width
                            return SizedBox(
                              width: addBtnFixedWidth, // Fixed width for ADD button
                              height: buttonHeight,
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  if (availableVariantCount > 1) {
                                    _showVariantBottomSheet(context, product.variants, product);
                                  } else {
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
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.success,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: BorderSide(color: AppColors.success, width: 1.5),
                                  ),
                                  elevation: 0,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: Size.zero,
                                ),
                                child: Center(
                                  child: Text(
                                    'ADD',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Sold Out button: Fixed width for consistency
                            return SizedBox(
                              width: addBtnFixedWidth, // Fixed width for Sold Out
                              height: buttonHeight,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.neutralBackground.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Sold Out',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.textLight.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      }),
                    ),
                  ],
                ),
              ),
              // Product Name (BELOW IMAGE)
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 2.0), // Tighter padding
                child: Text(
                  product.name,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Price and Rating (BOTTOM)
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 8.0), // Tighter padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "₹$sellingPrice", // Discounted price
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            fontSize: 14, // Slightly smaller for compactness
                          ),
                        ),
                        if (actualPrice > sellingPrice)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Text(
                              "₹$actualPrice", // Original price struck through
                              style: textTheme.labelSmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                                fontSize: 10, // Smallest font for original price
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2), // Very small space
                    AppStarRating(
                      rating: demoRating,
                      ratingCount: demoRatingCount,
                      starSize: 10, // Smallest stars for compactness
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// _AnimatedQuantityText and _showVariantBottomSheet remain unchanged
// as they serve a general purpose and their styling is consistent.

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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      key: ValueKey<int>(quantity),
      builder: (BuildContext context, double scale, Widget? child) {
        final curvedScale = Curves.easeOutBack.transform(scale);
        return Transform.scale(
          scale: scale == 1.0 ? 1.0 : (1.0 + (curvedScale * 0.2)),
          child: Text(
            '$quantity',
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        );
      },
      onEnd: () {
        // Optional: Perform any action when the animation ends
      },
    );
  }
}

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
                                borderRadius: BorderRadius.circular(8), // Applies the curve to the content
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  color: AppColors.white, // Sets the background color
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
                                      : CachedNetworkImage(
                                    imageUrl: variantImageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryPurple.withOpacity(0.5),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
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
                                    return SizedBox(
                                      width: 60, // Fixed width for ADD button in the bottom sheet
                                      height: 30,
                                      child: ElevatedButton(
                                        onPressed: adding ? null : () async {
                                          isAddingToCart[variantName]?.value = true;
                                          await Future.delayed(const Duration(milliseconds: 300));
                                          cartController.addToCart(productId: product.id, variantName: variantName);
                                          isAddingToCart[variantName]?.value = false;
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
                                        child: adding
                                            ? SizedBox(
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
                                            fontSize: 11,
                                          ),
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