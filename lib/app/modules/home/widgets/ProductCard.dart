// lib/widgets/enhanced_product_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math';

import '../../../controllers/cart_controller.dart';
import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';
import 'app_star_rating.dart';
import 'favorite_toggle_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final cartController = Get.find<CartController>();
    final hasImage = product.images.isNotEmpty && product.images[0].isNotEmpty;

    // Responsive dimensions for grid layout
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 480;

    // Optimized for 3x2 grid - no width constraints needed as GridView handles it
    final imageHeight = isSmallScreen ? 85.0 : isMediumScreen ? 95.0 : 105.0;
    final titleFontSize = isSmallScreen ? 11.0 : isMediumScreen ? 12.0 : 13.0;
    final priceFontSize = isSmallScreen ? 13.0 : isMediumScreen ? 14.0 : 15.0;
    final buttonHeight = isSmallScreen ? 32.0 : 36.0;

    // Price calculation logic
    final int originalPrice;
    final int sellingPrice;

    if (product.sellingPrice.length >= 2) {
      originalPrice = product.regularPrice ?? product.sellingPrice[product.sellingPrice.length - 2].price.toInt();
      sellingPrice = product.sellingPrice.last.price.toInt();
    } else if (product.sellingPrice.length == 1) {
      originalPrice = product.regularPrice ?? product.sellingPrice.first.price.toInt();
      sellingPrice = product.sellingPrice.first.price.toInt();
    } else {
      originalPrice = product.regularPrice ?? 0;
      sellingPrice = 0;
    }

    // Calculate discount percentage
    int discountPercent = 0;
    if (originalPrice > 0 && sellingPrice < originalPrice) {
      discountPercent = (((originalPrice - sellingPrice) / originalPrice) * 100).round();
    }

    final double demoRating = 3.5 + _random.nextDouble() * 1.5;
    final int demoRatingCount = 50 + _random.nextInt(500);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!.call(product);
          } else {
            Get.to(
                  () => ProductPage(product: product, heroTag: heroTag),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGreyBackground,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section - optimized for grid
              Expanded(
                flex: 4, // Takes 4/7 of the available height
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      child: Stack(
                        children: [
                          // Main product image
                          Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: double.infinity,
                                width: double.infinity,
                                color: AppColors.neutralBackground,
                                child: hasImage
                                    ? Image.network(
                                  product.images[0],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.success,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: isSmallScreen ? 24 : 28,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                )
                                    : Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: isSmallScreen ? 24 : 28,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Discount badge
                          if (discountPercent > 0)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 4 : 6,
                                    vertical: isSmallScreen ? 2 : 3
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isSmallScreen ? 8 : 9,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Favorite button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: FavoriteToggleButton(
                          productId: product.id.toString(),
                          iconSize: isSmallScreen ? 14 : 16,
                          padding: isSmallScreen ? 4 : 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product details section - optimized for grid
              Expanded(
                flex: 3, // Takes 3/7 of the available height
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 4 : 6
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name - takes available space
                      Expanded(
                        flex: 2,
                        child: Text(
                          product.name,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: titleFontSize,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Rating - compact for grid
                      SizedBox(
                        height: isSmallScreen ? 16 : 18,
                        child: AppStarRating(
                          rating: demoRating,
                          ratingCount: demoRatingCount,
                          starSize: isSmallScreen ? 12 : 14,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 2 : 4),

                      // Price section - compact
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '₹$sellingPrice',
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: priceFontSize,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (originalPrice > 0 && sellingPrice < originalPrice) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '₹$originalPrice',
                                  style: textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textLight,
                                    fontSize: isSmallScreen ? 10 : 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 4 : 6),

                      // Add to cart button - fixed height
                      SizedBox(
                        height: buttonHeight,
                        child: _buildAddToCartSection(context, cartController, isSmallScreen),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartSection(BuildContext context, CartController cartController, bool isSmallScreen) {
    return Obx(() {
      final Map<String, int> currentQuantities = cartController.productVariantQuantities.value;

      int totalProductQuantityInCart = 0;
      for (var variantEntry in product.variants.entries) {
        final String quantityKey = '${product.id}_${variantEntry.key}';
        totalProductQuantityInCart += currentQuantities[quantityKey] ?? 0;
      }

      final int availableVariantCount = product.variants.entries
          .where((entry) => entry.value > 0)
          .length;

      if (totalProductQuantityInCart > 0) {
        return _buildQuantitySelector(context, totalProductQuantityInCart, cartController, isSmallScreen);
      } else {
        return _buildAddButton(context, availableVariantCount, isSmallScreen);
      }
    });
  }

  Widget _buildQuantitySelector(BuildContext context, int quantity, CartController cartController, bool isSmallScreen) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasMultipleVariants = product.variants.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Decrement button
          Expanded(
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                if (hasMultipleVariants || quantity > 1) {
                  _showVariantBottomSheet(context, product.variants, product);
                } else {
                  final cartItemsForProduct = cartController.getCartItemsForProduct(productId: product.id);
                  if (cartItemsForProduct.isNotEmpty) {
                    final singleVariantName = cartItemsForProduct.keys.first;
                    cartController.removeFromCart(productId: product.id, variantName: singleVariantName);
                    _showSnackBar(context, 'Removed from cart', AppColors.danger);
                  }
                }
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  color: AppColors.white,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
            ),
          ),

          // Quantity display
          Container(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ),

          // Increment button
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                if (hasMultipleVariants) {
                  _showVariantBottomSheet(context, product.variants, product);
                } else {
                  final singleVariant = product.variants.entries.first;
                  cartController.addToCart(productId: product.id, variantName: singleVariant.key);
                  _showSnackBar(context, 'Added to cart', AppColors.success);
                }
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  color: AppColors.white,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, int availableVariantCount, bool isSmallScreen) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final cartController = Get.find<CartController>();

    if (availableVariantCount == 0) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lightGreyBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textLight.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            'Out of Stock',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          if (availableVariantCount > 1) {
            _showVariantBottomSheet(context, product.variants, product);
          } else {
            final singleVariant = product.variants.entries.firstWhere((element) => element.value > 0);
            cartController.addToCart(productId: product.id, variantName: singleVariant.key);
            _showSnackBar(context, 'Added to cart', AppColors.success);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.success,
          elevation: 0,
          side: BorderSide(color: AppColors.success, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: availableVariantCount > 1
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ADD',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
                fontSize: isSmallScreen ? 11 : 12,
              ),
            ),
            Text(
              '$availableVariantCount options',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.success.withOpacity(0.8),
                fontSize: isSmallScreen ? 8 : 9,
              ),
            ),
          ],
        )
            : Text(
          'ADD',
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Enhanced variant bottom sheet (unchanged)
void _showVariantBottomSheet(BuildContext context, Map<String, int> variantsMap, ProductModel product) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final CartController cartController = Get.find<CartController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      final List<MapEntry<String, int>> variantEntries = variantsMap.entries.toList();
      final Map<String, RxBool> isAddingToCart = {};
      final Map<String, RxBool> isRemovingFromCart = {};

      for (var entry in variantEntries) {
        isAddingToCart[entry.key] = false.obs;
        isRemovingFromCart[entry.key] = false.obs;
      }

      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Choose Variant',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Variants list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: variantEntries.length,
                    itemBuilder: (context, index) {
                      final entry = variantEntries[index];
                      final variantName = entry.key;
                      final variantStock = entry.value;
                      final bool isOutOfStock = variantStock <= 0;

                      final String variantImageUrl = product.images.isNotEmpty
                          ? product.images[0]
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOutOfStock
                                ? AppColors.textLight.withOpacity(0.2)
                                : AppColors.lightGreyBackground,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Variant image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  color: AppColors.neutralBackground,
                                  child: variantImageUrl.isNotEmpty
                                      ? Image.network(
                                    variantImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.image, color: AppColors.textLight),
                                  )
                                      : Icon(Icons.image, color: AppColors.textLight),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Variant details
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
                                    if (isOutOfStock) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Out of Stock',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Add/quantity controls
                              if (!isOutOfStock)
                                Obx(() {
                                  final currentVariantQuantity = cartController.getVariantQuantity(
                                    productId: product.id,
                                    variantName: variantName,
                                  );
                                  final bool adding = isAddingToCart[variantName]?.value ?? false;
                                  final bool removing = isRemovingFromCart[variantName]?.value ?? false;

                                  if (currentVariantQuantity > 0) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: removing ? null : () async {
                                              isRemovingFromCart[variantName]?.value = true;
                                              HapticFeedback.lightImpact();
                                              await Future.delayed(const Duration(milliseconds: 200));
                                              cartController.removeFromCart(
                                                productId: product.id,
                                                variantName: variantName,
                                              );
                                              isRemovingFromCart[variantName]?.value = false;
                                            },
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: removing
                                                  ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.white,
                                                ),
                                              )
                                                  : Icon(
                                                Icons.remove,
                                                color: AppColors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Text(
                                              '$currentVariantQuantity',
                                              style: textTheme.labelMedium?.copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: adding ? null : () async {
                                              isAddingToCart[variantName]?.value = true;
                                              HapticFeedback.lightImpact();
                                              await Future.delayed(const Duration(milliseconds: 200));
                                              cartController.addToCart(
                                                productId: product.id,
                                                variantName: variantName,
                                              );
                                              isAddingToCart[variantName]?.value = false;
                                            },
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: adding
                                                  ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.white,
                                                ),
                                              )
                                                  : Icon(
                                                Icons.add,
                                                color: AppColors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return ElevatedButton(
                                      onPressed: adding ? null : () async {
                                        isAddingToCart[variantName]?.value = true;
                                        HapticFeedback.lightImpact();
                                        await Future.delayed(const Duration(milliseconds: 200));
                                        cartController.addToCart(
                                          productId: product.id,
                                          variantName: variantName,
                                        );
                                        isAddingToCart[variantName]?.value = false;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
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
                                        style: textTheme.labelMedium?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w800,
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
