import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math';



import '../../../controllers/cart_controller.dart';
import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';
import 'app_star_rating.dart';
import 'favorite_toggle_button.dart'; // Add this import

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

  static final Random _random = Random();

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
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              if (hasMultipleVariants || totalQuantity > 1) {
                _showVariantBottomSheet(context, product);
              } else {
                final cartItemsForProduct = cartController.getCartItemsForProduct(productId: product.id);
                if (cartItemsForProduct.isNotEmpty) {
                  final singleVariantName = cartItemsForProduct.keys.first;
                  await cartController.removeFromCart(productId: product.id, variantName: singleVariantName);
                }
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.remove, color: AppColors.white, size: 16),
            ),
          ),
          Flexible(
            child: _AnimatedQuantityText(
              quantity: totalQuantity,
              textStyle: textTheme.labelSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              if (hasMultipleVariants) {
                _showVariantBottomSheet(context, product);
              } else {
                final singleVariant = product.variants.entries.first;
                await cartController.addToCart(productId: product.id, variantName: singleVariant.key);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.add, color: AppColors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Build ADD button with variant indicator inside the button
  Widget _buildAddButtonWithVariantCount(
      BuildContext context,
      int availableVariantCount,
      ProductModel product,
      CartController cartController,
      ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    const double addBtnFixedWidth = 60.0;
    const double buttonHeight = 28.0;

    return SizedBox(
      width: addBtnFixedWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: () async {
          HapticFeedback.lightImpact();
          if (availableVariantCount > 1) {
            _showVariantBottomSheet(context, product);
          } else {
            final singleVariant = product.variants.entries
                .firstWhere((element) => element.value > 0);
            await cartController.addToCart(
              productId: product.id,
              variantName: singleVariant.key,
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
        child: Stack(
          children: [
            Center(
              child: Text(
                'ADD',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (availableVariantCount > 1)
              Positioned(
                bottom: 0,
                right: 1,
                child: Container(
                  width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$availableVariantCount Options',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final cartController = Get.find<CartController>();

    final hasImage = product.images.isNotEmpty && product.images[0].isNotEmpty;

    final int sellingPrice;
    int actualPrice = 0;
    String discountPercentage = '';

    if (product.sellingPrice.isNotEmpty) {
      sellingPrice = product.sellingPrice.last.price.toInt();
      if (product.sellingPrice.isNotEmpty) {
        actualPrice = product.sellingPrice.last.price.toInt();
        if (actualPrice > 0 && sellingPrice < actualPrice) {
          double discount = ((actualPrice - sellingPrice) / actualPrice) * 100;
          discountPercentage = '${discount.round()}% off';
        }
      } else {
        actualPrice = sellingPrice;
      }
    } else {
      sellingPrice = 0;
      actualPrice = 0;
    }

    final double demoRating = 3.0 + _random.nextDouble() * 2.0;
    final int demoRatingCount = 10 + _random.nextInt(1000);

    const double addBtnFixedWidth = 60.0;
    const double buttonHeight = 28.0;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
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
              AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: AppColors.neutralBackground,
                            child: hasImage
                                ? CachedNetworkImage(
                              imageUrl: product.images[0],
                              fit: BoxFit.contain,
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
                    // Discount badge
                    if (discountPercentage.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
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
                    // ✅ FAVORITE BUTTON - Added in top-right corner
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FavoriteToggleButton(
                          productId: product.id.toString(),
                          iconSize: 14,
                          padding: 6,
                        ),
                      ),
                    ),
                    // Cart button
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Obx(() {
                        final variantQuantities = cartController.productVariantQuantities;

                        int totalProductQuantityInCart = 0;
                        for (var variantEntry in product.variants.entries) {
                          final String quantityKey = '${product.id}_${variantEntry.key}';
                          totalProductQuantityInCart += variantQuantities[quantityKey] ?? 0;
                        }

                        final int availableVariantCount = product.variants.entries
                            .where((entry) => entry.value > 0)
                            .length;

                        if (totalProductQuantityInCart > 0) {
                          return _buildQuantitySelectorButton(
                            totalProductQuantityInCart,
                            product,
                            cartController,
                            context,
                          );
                        } else {
                          if (availableVariantCount > 0) {
                            return _buildAddButtonWithVariantCount(
                              context,
                              availableVariantCount,
                              product,
                              cartController,
                            );
                          } else {
                            return SizedBox(
                              width: addBtnFixedWidth,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 2.0),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppStarRating(
                      rating: demoRating,
                      ratingCount: demoRatingCount,
                      starSize: 12,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "₹$sellingPrice",
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                        if (actualPrice > sellingPrice)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Text(
                              "₹$actualPrice",
                              style: textTheme.labelSmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
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

// Variant bottom sheet implementation
void _showVariantBottomSheet(BuildContext context, ProductModel product) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final CartController cartController = Get.find<CartController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      final List<MapEntry<String, int>> variantEntries = product.variants.entries
          .where((entry) => entry.value > 0)
          .toList();

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
                                  color: AppColors.white,
                                  child: CachedNetworkImage(
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
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Obx(() {
                                final currentVariantQuantity = cartController.productVariantQuantities['${product.id}_$variantName'] ?? 0;
                                final bool isProcessing = cartController.isLoading.value;

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
                                          onTap: isProcessing ? null : () async {
                                            HapticFeedback.lightImpact();
                                            await cartController.removeFromCart(productId: product.id, variantName: variantName);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: isProcessing
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
                                          onTap: isProcessing ? null : () async {
                                            HapticFeedback.lightImpact();
                                            await cartController.addToCart(productId: product.id, variantName: variantName);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: isProcessing
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
                                    width: 60,
                                    height: 30,
                                    child: ElevatedButton(
                                      onPressed: isProcessing ? null : () async {
                                        HapticFeedback.lightImpact();
                                        await cartController.addToCart(productId: product.id, variantName: variantName);
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
                                        child: isProcessing
                                            ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.success,
                                          ),
                                        )
                                            : Text(
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
