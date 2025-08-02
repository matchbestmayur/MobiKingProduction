// lib/screens/product_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as html_parser; // ADD THIS IMPORT
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';
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
  final CartController cartController = Get.find();
  final ProductController productController = Get.find();
  final WishlistController wishlistController = Get.find();
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

  // ADD THIS METHOD - HTML to plain text conversion
  String _convertHtmlToPlainText(String htmlText) {
    if (htmlText.isEmpty) return htmlText;

    try {
      // Parse the HTML
      final document = html_parser.parse(htmlText);

      // Extract plain text
      String plainText = document.body?.text ?? htmlText;

      // Clean up extra whitespace
      plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();

      return plainText;
    } catch (e) {
      // If parsing fails, return the original text
      debugPrint('Error parsing HTML: $e');
      return htmlText;
    }
  }

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
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                                ? _convertHtmlToPlainText(product.description) // CHANGE: Use HTML conversion
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
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                                          _convertHtmlToPlainText(point), // CHANGE: Use HTML conversion
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
                                                            color: Colors.black, // Bold black for left side
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      // Right content column (light grey)
                                                      Expanded(
                                                        child: Text(
                                                          _convertHtmlToPlainText(info.content), // CHANGE: Use HTML conversion
                                                          style: textTheme.bodyMedium?.copyWith(
                                                            color: Colors.grey.shade700, // Subtle grey for right side
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
                          children: List.generate(variantNames.length, (index) {
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
                              // White background in all states
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

                  const SizedBox(height: 24), // Keep larger spacing for major sections

                  // Complete "You might also like" section with working navigation
                  Obx(() {
                    if (productController.allProducts.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final String? parentCategory = widget.product.categoryId.isNotEmpty
                        ? widget.product.categoryId
                        : null;
                    final List<ProductModel> relatedProducts = productController.getProductsInSameParentCategory(
                      widget.product.id,
                      parentCategory,
                    );

                    if (relatedProducts.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                          child: Text(
                            'You might also like',
                            style: textTheme.headlineSmall?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedProducts.length,
                            itemBuilder: (context, index) {
                              final relatedProduct = relatedProducts[index];
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: AllProductGridCard(
                                      product: relatedProduct,
                                      heroTag: 'product_image_${product.id}_${product.name}_all_view_$index',
                                      onTap: (product) {
                                        Get.to(ProductPage(
                                          product: product,
                                          heroTag: 'product_image_${product.id}_${product.name}_all_view_$index',
                                        ));
                                      }),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 70), // Height of the bottom bar
                ],
              ),
            ),
          ),
          // Bottom bar
          _buildBottomCartBar(context)
        ],
      ),
    );
  }

  void _navigateToRelatedProduct(ProductModel product, String heroTag) {
    try {
      HapticFeedback.lightImpact();
      debugPrint('🚀 Navigating to related product: ${product.name} with heroTag: $heroTag');
      // Clear any existing routes to prevent conflicts
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.to(
            () => ProductPage(
          product: product,
          heroTag: heroTag,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        preventDuplicates: true,
        popGesture: true,
      )?.then((_) {
        debugPrint('✅ Successfully navigated back from ${product.name}');
      }).catchError((error) {
        debugPrint('❌ Navigation error: $error');
      });
    } catch (e) {
      debugPrint('❌ Exception during navigation: $e');
      // Fallback navigation without hero animation
      _fallbackNavigation(product);
    }
  }

  // Fallback navigation method
  void _fallbackNavigation(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPage(
          product: product,
          heroTag: 'fallback_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
      decoration: BoxDecoration(
        color: AppColors.neutralBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGreyBackground,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recommend_outlined,
              size: 40,
              color: AppColors.textLight.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No recommendations available',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for suggestions',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textLight.withOpacity(0.8),
              ),
            ),
          ],
        ),
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

      return SafeArea( // WRAP WITH SafeArea
        bottom: true, // Ensure it applies padding to the bottom
        top: false, // We only care about the bottom for a bottom bar
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
