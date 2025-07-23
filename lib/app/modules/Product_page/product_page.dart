// lib/screens/product_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:mobiking/app/modules/home/widgets/ProductCard.dart';
import 'package:mobiking/app/themes/app_theme.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/wishlist_controller.dart';
import '../../data/product_model.dart';
import '../home/widgets/app_star_rating.dart';
import 'widgets/product_image_banner.dart';
import 'widgets/product_title_price.dart';
import 'widgets/featured_product_banner.dart';
import 'widgets/collapsible_section.dart';
import 'widgets/animated_cart_button.dart';

// Add SingleTickerProviderStateMixin for animation controller
class ProductPage extends StatefulWidget {
  final ProductModel product;
  final String heroTag;

  const ProductPage({
    super.key,
    required this.product,
    required this.heroTag,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with SingleTickerProviderStateMixin {
  int selectedVariantIndex = 0;

  final TextEditingController _pincodeController = TextEditingController();
  final RxBool _isCheckingDelivery = false.obs;
  final RxString _deliveryStatusMessage = ''.obs;
  final RxBool _isDeliverable = false.obs;

  final CartController cartController = Get.find<CartController>();
  final ProductController productController = Get.find<ProductController>();
  final WishlistController wishlistController = Get.find<WishlistController>();

  final RxInt _currentVariantStock = 0.obs;
  final RxString _currentSelectedVariantName = ''.obs;

  // Controller for scroll events to hide/show bottom bar
  final ScrollController _scrollController = ScrollController();

  // Animation controller for sliding the bottom bar
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  // State variable to control the visibility of product details
  final RxBool _productDetailsVisible = false.obs; // Initially hidden

  // Define a consistent horizontal padding for the main content
  static const double _horizontalPagePadding = 16.0;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      int firstAvailableIndex = -1;
      for (int i = 0; i < widget.product.variants.length; i++) {
        final variantKey = widget.product.variants.keys.elementAt(i);
        if ((widget.product.variants[variantKey] ?? 0) > 0) {
          firstAvailableIndex = i;
          break;
        }
      }

      if (firstAvailableIndex != -1) {
        selectedVariantIndex = firstAvailableIndex;
        _currentSelectedVariantName.value = widget.product.variants.keys.elementAt(selectedVariantIndex);
      } else {
        selectedVariantIndex = 0;
        _currentSelectedVariantName.value = widget.product.variants.keys.elementAt(selectedVariantIndex);
      }
    } else {
      _currentSelectedVariantName.value = 'Default Variant';
    }

    _pincodeController.addListener(_resetDeliveryStatus);
    _syncVariantData();

    // Initialize animation controller
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Define the slide animation: from no offset (visible) to slide down (100% of its height)
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero, // Visible position
      end: const Offset(0, 1), // Hidden position (slides down by its full height)
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initially show the bar
    _slideAnimationController.forward();

    // Add scroll listener for the bottom bar animation
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_resetDeliveryStatus);
    _pincodeController.dispose();
    // Dispose scroll controller and animation controller
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _slideAnimationController.dispose(); // Dispose animation controller
    super.dispose();
  }

  void _resetDeliveryStatus() {
    if (_deliveryStatusMessage.isNotEmpty) {
      _deliveryStatusMessage.value = '';
      _isDeliverable.value = false;
    }
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // User is scrolling down, hide the bar
      if (_slideAnimationController.status != AnimationStatus.forward) {
        _slideAnimationController.forward();
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      // User is scrolling up, show the bar
      if (_slideAnimationController.status != AnimationStatus.reverse) {
        _slideAnimationController.reverse();
      }
    }
  }

  void onVariantSelected(int index) {
    final variantKey = widget.product.variants.keys.elementAt(index);
    final isVariantOutOfStock = (widget.product.variants[variantKey] ?? 0) <= 0;

    if (!isVariantOutOfStock) {
      setState(() {
        selectedVariantIndex = index;
        _currentSelectedVariantName.value = variantKey;
        _syncVariantData();
      });
    } else {
      Get.snackbar(
        'Out of Stock',
        'This variant is currently out of stock.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.info_outline, color: Colors.white),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        animationDuration: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _syncVariantData() {
    if (widget.product.variants.isNotEmpty &&
        selectedVariantIndex >= 0 &&
        selectedVariantIndex < widget.product.variants.length) {
      final variantKey = widget.product.variants.keys.elementAt(selectedVariantIndex);
      _currentVariantStock.value = widget.product.variants[variantKey] ?? 0;
    } else {
      _currentVariantStock.value = widget.product.totalStock;
    }
  }

  Future<void> _incrementQuantity() async {
    final String productId = widget.product.id.toString();
    final String variantName = _currentSelectedVariantName.value;

    final quantityInCart = cartController.getVariantQuantity(
      productId: productId,
      variantName: variantName,
    );

    if (cartController.isLoading.value || _currentVariantStock.value <= 0 ||
        _currentVariantStock.value <= quantityInCart) {
      if (_currentVariantStock.value <= 0) {
        Get.snackbar(
          'Out of Stock',
          'The selected variant is currently out of stock.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.info_outline, color: Colors.white),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          animationDuration: const Duration(milliseconds: 300),
          duration: const Duration(seconds: 3),
        );
      } else if (_currentVariantStock.value <= quantityInCart) {
        Get.snackbar(
          'Limit Reached',
          'You have reached the maximum available quantity for this variant.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.info_outline, color: Colors.white),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          animationDuration: const Duration(milliseconds: 300),
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }

    cartController.isLoading.value = true;
    try {
      await cartController.addToCart(productId: productId, variantName: variantName);
    } finally {
      cartController.isLoading.value = false;
    }
  }

  Future<void> _decrementQuantity() async {
    final String productId = widget.product.id.toString();
    final String variantName = _currentSelectedVariantName.value;

    final quantityInCart = cartController.getVariantQuantity(
      productId: productId,
      variantName: variantName,
    );

    if (quantityInCart <= 0 || cartController.isLoading.value) return;

    cartController.isLoading.value = true;
    try {
      await cartController.removeFromCart(productId: productId, variantName: variantName);
    } finally {
      cartController.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final originalPrice =
    product.sellingPrice.isNotEmpty ? product.sellingPrice.first.price : 0;
    final discountedPrice = product.sellingPrice.length > 1
        ? product.sellingPrice[1].price
        : originalPrice;

    // Calculate discount percentage
    final double discountPercentage = originalPrice > 0
        ? ((originalPrice - discountedPrice) / originalPrice * 100)
        : 0;
    final String discountBadgeText =
    discountPercentage > 0 ? '${discountPercentage.toStringAsFixed(0)}% OFF' : '';

    // Dummy data for price per unit, rating, reviews
    final double pricePer100ml = (discountedPrice / 20).toPrecision(2); // Example for 2L (2000ml), so per 100ml is /20
    const double productRating = 4.5; // Example rating
    const int reviewCount = 881; // Example review count

    final variantNames = product.variants.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Banner (full width, with zoom/share)
                  Obx(() {
                    final isFavorite = wishlistController.wishlist.any((p) => p.id == product.id);
                    return ProductImageBanner(
                      productRating: 4.5,
                            reviewCount: 450,
                      productId: product.id.toString(),
                      imageUrls: product.images,
                      badgeText: discountBadgeText.isNotEmpty ? discountBadgeText : null,
                      isFavorite: isFavorite,
                      onBack: () => Get.back(),
                      onFavorite: () {
                        if (isFavorite) {
                          wishlistController.removeFromWishlist(product.id);
                        } else {
                          wishlistController.addToWishlist(product.id.toString());
                        }
                      },
                      heroTag: widget.heroTag,
                    );
                  }),

                  // Product Title & Price Card with Toggle Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20), // Outer padding
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutralBackground,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Only horizontal padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Title & Price
                          ProductTitleAndPrice(
                            title: product.fullName,
                            originalPrice: originalPrice.toDouble(),
                            discountedPrice: discountedPrice.toDouble(),
                          ),
                          const SizedBox(height: 8),

                          // View/Hide Product Details Button
                          SizedBox(
                            width: double.maxFinite,
                            height: 36,
                            child: Obx(() => ElevatedButton.icon(
                              onPressed: () {
                                _productDetailsVisible.value = !_productDetailsVisible.value;
                                debugPrint('View product details tapped! Visible: ${_productDetailsVisible.value}');
                              },
                              icon: Icon(
                                _productDetailsVisible.value
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: AppColors.success,
                                size: 16,
                              ),
                              label: Text(
                                _productDetailsVisible.value
                                    ? 'Hide product details'
                                    : 'View product details',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success.withOpacity(0.1),
                                foregroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )),
                          ),

                          const SizedBox(height: 8), // Space after the button (optional)
                          Obx(
                                () => AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(), // Hidden state: shows nothing
                              secondChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- Product Description Section ---
                                  Padding(
                                    padding: const EdgeInsets.symmetric( vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Product Description',
                                          style: textTheme.titleMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          child: Text(
                                            product.description.isNotEmpty
                                                ? product.description
                                                : 'No detailed description is available for this product. This product offers cutting-edge technology and superior performance, designed to meet your everyday needs with efficiency and style. Enjoy seamless integration and robust features that enhance your overall user experience.',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: AppColors.textMedium,
                                              height: 1.5, // improves readability
                                            ),
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),

                                  // --- Product Description Points Section (NEW) ---
                                  if (product.descriptionPoints.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric( vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Product Description Points',
                                            style: textTheme.titleMedium?.copyWith(
                                              color: AppColors.textDark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: product.descriptionPoints.map((point) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '• ',
                                                        style: textTheme.bodyMedium?.copyWith(
                                                          color: AppColors.textDark,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          point,
                                                          style: textTheme.bodyMedium?.copyWith(
                                                            color: AppColors.textMedium,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),



                                  // --- Key Information Section (Modified for table-like format) ---
                                  // Key Information Section, displayed in a table-like format
                                  // --- Key Information Section (Styled like a table) ---
                                  if (product.keyInformation.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            'Highlights',
                                            style: textTheme.titleMedium?.copyWith(
                                              color: AppColors.textDark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                            child: Column(
                                              children: product.keyInformation.map((info) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Left title column (black or dark text)
                                                      SizedBox(
                                                        width: 110,
                                                        child: Text(
                                                          info.title,
                                                          style: textTheme.bodyMedium?.copyWith(
                                                            color: Colors.black, // 💡 Bold black for left side
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),

                                                      // Right content column (light grey)
                                                      Expanded(
                                                        child: Text(
                                                          info.content,
                                                          style: textTheme.bodyMedium?.copyWith(
                                                            color: Colors.grey.shade700, // 💡 Subtle grey for right side
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                ],
                              ),
                              crossFadeState: _productDetailsVisible.value
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                              alignment: Alignment.topLeft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                  if (variantNames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                      child: CollapsibleSection(
                        title: 'Select Variant',
                        initiallyExpanded: true,
                        content: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List<Widget>.generate(variantNames.length, (index) {
                            final isSelected = selectedVariantIndex == index;
                            final variantStockValue = product.variants[variantNames[index]] ?? 0;
                            final isVariantOutOfStock = variantStockValue <= 0;

                            return ChoiceChip(
                              label: Text(
                                variantNames[index] + (isVariantOutOfStock ? ' (Out of Stock)' : ''),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected && !isVariantOutOfStock) {
                                  onVariantSelected(index);
                                }
                              },

                              // 🌟 White background in all states
                              selectedColor: Colors.white,
                              backgroundColor: Colors.white,

                              labelStyle: textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? AppColors.success // Green text when selected
                                    : (isVariantOutOfStock
                                    ? AppColors.danger.withOpacity(0.7) // Red-ish for out of stock
                                    : AppColors.textDark.withOpacity(0.8)),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.success // Green border when selected
                                      : (isVariantOutOfStock
                                      ? AppColors.danger.withOpacity(0.4)
                                      : Colors.grey.shade300), // Default grey border
                                  width: 1,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),


/*// Animated section for Product Description and Key Information
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding, vertical: 8.0),
                    child: SizedBox(
                      width: double.maxFinite,
                      // Removed fixed width: double.infinity to make it small
                      height: 36, // Smaller fixed height for the button
                      child: Obx( // Wrap with Obx to react to _productDetailsVisible changes
                            () => ElevatedButton.icon(
                          onPressed: () {
                            _productDetailsVisible.value = !_productDetailsVisible.value;
                            debugPrint('View product details tapped! Visible: ${_productDetailsVisible.value}');
                          },
                          icon: Icon(
                            _productDetailsVisible.value ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: AppColors.success, // Green icon color
                            size: 16, // Smaller icon size
                          ),
                          label: Text(
                            _productDetailsVisible.value ? 'Hide product details' : 'View product details',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith( // Use labelLarge for smaller text
                              color: AppColors.success, // Green text color
                              fontWeight: FontWeight.w600,
                              fontSize: 12, // Smaller font size for a compact look
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success.withOpacity(0.1), // Light green background with reduced opacity
                            foregroundColor: AppColors.success, // Text/icon color (though overridden by label/icon color)
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjusted padding to make it smaller
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Slightly smaller border radius
                              side: BorderSide.none, // No explicit border
                            ),
                            elevation: 0, // No elevation
                            shadowColor: Colors.transparent, // No shadow
                            minimumSize: Size.zero, // Important: Allows the button to shrink to content size
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink tap area
                          ),
                        ),
                      ),
                    ),
                  ),*/
                 /* Obx(
                        () => AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(), // Hidden state: shows nothing
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Product Description Section ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Description',
                                  style: textTheme.titleMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description.isNotEmpty
                                      ? product.description
                                      : 'No detailed description is available for this product. This product offers cutting-edge technology and superior performance, designed to meet your everyday needs with efficiency and style. Enjoy seamless integration and robust features that enhance your overall user experience.',
                                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                                ),
                              ],
                            ),
                          ),

                          // --- Product Description Points Section (NEW) ---
                          if (product.descriptionPoints.isNotEmpty) // Only show if points exist
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8), // Spacing above points
                                  ...product.descriptionPoints.map((point) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0), // Spacing between points
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Text(
                                            '•', // Bullet point
                                            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            point,
                                            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),


                          // --- Key Information Section (Modified for table-like format) ---
                          // Key Information Section, displayed in a table-like format
                          if (product.keyInformation.isNotEmpty) // Only show if key info exists
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8), // Spacing above Key Information section
                                  Text(
                                    'Key Information',
                                    style: textTheme.titleMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  // This Column contains the "rows" of your table-like structure
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, // Ensures titles align to the left
                                    children: product.keyInformation.map((info) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0), // Spacing between each "table row"
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes title to left, content to right
                                        children: [
                                          // Left "column" (Title)
                                          Text(
                                            info.title,
                                            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                                          ),
                                          const SizedBox(width: 16), // Spacing between title and content
                                          // Right "column" (Content)
                                          Expanded( // Allows content to wrap and takes remaining space
                                            child: Text(
                                              info.content,
                                              textAlign: TextAlign.end, // Aligns content text to the right
                                              style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      crossFadeState: _productDetailsVisible.value
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                      alignment: Alignment.topLeft,
                    ),
                  ),*/
                  const SizedBox(height: 24), // Keep larger spacing for major sections
                  // START: Replaced "You might also like" Placeholder
// ... (previous code before the Obx block)

                  Obx(() {
                    // If products are still being fetched and the list is empty, or
                    // if products have been fetched but the list is genuinely empty.
                    if (productController.allProducts.isEmpty) {
                      // Return an empty SizedBox or Container to display nothing
                      return const SizedBox.shrink(); // Or Container()
                    }
                    // Otherwise, process and display the related products
                    else {
                      // Determine the parent category of the current product.
                      // Using product.categoryId as per your updated code.
                      final String? parentCategory = widget.product.categoryId.isNotEmpty
                          ? widget.product.categoryId
                          : null;

                      // Filter products from the controller that belong to the same parent category
                      // and exclude the current product itself.
                      final List<ProductModel> relatedProducts = productController.getProductsInSameParentCategory(
                        widget.product.id, // Current product's ID
                        parentCategory,     // Parent category to filter by
                      );

                      if (relatedProducts.isEmpty) {
                        // If no related products are found in the same category, display nothing
                        return const SizedBox.shrink(); // Or Container()
                      }

                      // If related products ARE found, then show the title and the list
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                            child: Text(
                              'You might also like',
                              style: textTheme.headlineSmall?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 275, // Fixed height for the horizontal ListView of product cards
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                              scrollDirection: Axis.horizontal, // Make the list horizontal
                              itemCount: relatedProducts.length,
                              itemBuilder: (context, index) {
                                final relatedProduct = relatedProducts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0), // Spacing between cards
                                  child: GestureDetector(
                                    onTap: () {
                                      // Navigate to the ProductPage of the tapped related product
                                      Get.to(() => ProductPage(
                                        product: relatedProduct,
                                        heroTag: 'related_product_${relatedProduct.id}',
                                      ));
                                    },
                                    // Make sure you are using 'ProductCard' (PascalCase) here,
                                    // consistent with your import `ProductCard.dart`
                                    child: ProductCards( // Changed from ProductCards to ProductCard
                                      product: relatedProduct,
                                      heroTag: 'related_product_${relatedProduct.id}', // Unique heroTag for each card
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  }),
/*// ... (rest of your build method code)
                  const SizedBox(height: 12), // Keep larger spacing for major sections

                  // Featured Offer section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                    child: Text(
                      'Featured Offer',
                      style: textTheme.headlineSmall?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FeaturedProductBanner(
                        imageUrl: product.images.length > 1 && product.images[1] is String
                            ? product.images[1].toString()
                            : 'https://via.placeholder.com/400x200?text=Featured+Product',
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Explore More Categories section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                    child: Text(
                      'Explore More Categories',
                      style: textTheme.headlineSmall?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                    child: Container(
                      height: 200,
                      color: AppColors.neutralBackground,
                      alignment: Alignment.center,
                      child: Text('Placeholder for Shop by Category / GroupGridSection',
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
                    ),
                  ),
                  // Add a final SizedBox to ensure there's enough scroll space above the bottom bar*/
                  const SizedBox(height: 70), // Height of the bottom bar
                ],
              ),
            ),
          ),
          // Bottom bar, now animated with SlideTransition
          // Remove animation
          _buildBottomCartBar(context)

        ],
      ),
    );
  }
  Widget _buildBottomCartBar(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final product = widget.product; // Assuming 'widget' context is available

    final double displayPrice = product.sellingPrice.length > 1
        ? product.sellingPrice.last.price.toDouble()
        : product.sellingPrice.isNotEmpty
        ? product.sellingPrice.first.price.toDouble()
        : 0.0;

    return Obx(() {
      final quantityInCartForSelectedVariant = cartController.getVariantQuantity(
        productId: product.id,
        variantName: _currentSelectedVariantName.value,
      );
      final bool isBusy = cartController.isLoading.value;
      final bool isOutOfStock = _currentVariantStock.value <= 0;

      final bool isInCart = quantityInCartForSelectedVariant > 0;
      final bool canIncrement =
          quantityInCartForSelectedVariant < _currentVariantStock.value && !isBusy;
      final bool canDecrement = quantityInCartForSelectedVariant > 0 && !isBusy;

      return SafeArea( // <--- WRAP WITH SafeArea
        bottom: true, // <--- Ensure it applies padding to the bottom
        top: false,   // <--- We only care about the bottom for a bottom bar
        child: Container(
          height: 70, // Fixed height for the bar
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white, // Background of the entire bar
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
                    ),
                    Text(
                      '₹${displayPrice.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              AnimatedCartButton(
                isInCart: isInCart,
                isBusy: isBusy,
                isOutOfStock: isOutOfStock,
                quantityInCart: quantityInCartForSelectedVariant,
                onAdd: _incrementQuantity,
                onIncrement: _incrementQuantity,
                onDecrement: _decrementQuantity,
                canIncrement: canIncrement,
                canDecrement: canDecrement,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      );
    });
  }
}