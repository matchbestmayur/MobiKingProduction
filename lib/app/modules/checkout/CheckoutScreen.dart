import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/Product_page/product_page.dart';

import 'package:mobiking/app/modules/address/AddressPage.dart';
import 'package:mobiking/app/modules/checkout/widget/bill_section.dart';
import 'package:mobiking/app/modules/checkout/widget/cart_item_tile.dart';
import 'package:mobiking/app/modules/checkout/widget/payment_method_selection_screen.dart';
import 'package:mobiking/app/modules/checkout/widget/suggested_product_card.dart';

import '../../controllers/address_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/product_controller.dart';
import '../../data/AddressModel.dart';
import '../../data/product_model.dart';
import '../../themes/app_theme.dart';
import '../home/widgets/AllProductGridCard.dart';
import '../home/widgets/ProductCard.dart';

class CheckoutScreen extends StatelessWidget {
  CheckoutScreen({Key? key}) : super(key: key);

  final cartController = Get.find<CartController>();
  final addressController = Get.find<AddressController>();
  final orderController = Get.find<OrderController>();
  final productController = Get.find<ProductController>();

  // Add an RxString to hold the selected payment method
  final RxString _selectedPaymentMethod = ''.obs;

  // ✅ COUPON SYSTEM: Complete Coupon Data Structure
  final RxString _couponCode = ''.obs;
  final RxBool _isCouponApplied = false.obs;
  final RxDouble _couponDiscount = 0.0.obs;
  final RxString _appliedCouponCode = ''.obs;
  final RxBool _isCouponLoading = false.obs;
  final RxString _couponType = ''.obs; // 'percentage' or 'fixed'
  final RxString _couponDescription = ''.obs;
  final TextEditingController _couponController = TextEditingController();

  // ✅ DEMO: Complete Coupon Database
  final Map<String, Map<String, dynamic>> _demoValidCoupons = {
    'WELCOME10': {
      'discount': 10.0,
      'type': 'fixed',
      'description': 'Welcome bonus for new users',
      'minOrder': 99.0,
      'maxDiscount': 10.0,
      'validUntil': '31 Dec 2025',
      'category': 'Welcome Offer',
      'icon': Icons.celebration_outlined,
      'color': Colors.orange,
    },
    'SAVE20': {
      'discount': 20.0,
      'type': 'fixed',
      'description': 'Flat ₹20 off on all orders',
      'minOrder': 199.0,
      'maxDiscount': 20.0,
      'validUntil': '31 Dec 2025',
      'category': 'General Discount',
      'icon': Icons.local_offer_outlined,
      'color': Colors.green,
    },
    'FIRSTORDER': {
      'discount': 15.0,
      'type': 'percentage',
      'description': '15% off on first order',
      'minOrder': 149.0,
      'maxDiscount': 100.0,
      'validUntil': '31 Dec 2025',
      'category': 'First Time User',
      'icon': Icons.star_outline,
      'color': Colors.purple,
    },
    'PREMIUM25': {
      'discount': 25.0,
      'type': 'fixed',
      'description': 'Premium member exclusive',
      'minOrder': 299.0,
      'maxDiscount': 25.0,
      'validUntil': '31 Dec 2025',
      'category': 'Premium',
      'icon': Icons.diamond_outlined,
      'color': Colors.blue,
    },
    'MEGA50': {
      'discount': 10.0,
      'type': 'percentage',
      'description': '10% off, up to ₹50',
      'minOrder': 499.0,
      'maxDiscount': 50.0,
      'validUntil': '31 Dec 2025',
      'category': 'Mega Deal',
      'icon': Icons.flash_on_outlined,
      'color': Colors.red,
    },
    'SUMMER30': {
      'discount': 30.0,
      'type': 'fixed',
      'description': 'Summer special discount',
      'minOrder': 399.0,
      'maxDiscount': 30.0,
      'validUntil': '31 Aug 2025',
      'category': 'Seasonal',
      'icon': Icons.wb_sunny_outlined,
      'color': Colors.amber,
    },
  };

  // ✅ Calculate current cart total
  double _calculateCartTotal() {
    return cartController.cartItems.fold(0.0, (sum, item) {
      final productData = item['productId'];
      final product = productData is Map<String, dynamic>
          ? ProductModel.fromJson(productData)
          : ProductModel(
          id: '', name: '', fullName: '', slug: '', description: '',
          images: [], sellingPrice: [], variants: {}, active: false,
          newArrival: false, liked: false, bestSeller: false,
          recommended: false, categoryId: '', stockIds: [],
          orderIds: [], groupIds: [], totalStock: 0,
          descriptionPoints: [], keyInformation: []
      );
      final quantity = item['quantity'] ?? 1;
      double itemPrice = 0.0;
      if (product.sellingPrice.isNotEmpty && product.sellingPrice[0].price != null) {
        itemPrice = product.sellingPrice[0].price!.toDouble();
      }
      return sum + itemPrice * quantity;
    });
  }

  // ✅ ENHANCED: Smart Coupon Validation with Complete Logic
  void _applyCoupon() async {
    final couponCode = _couponController.text.trim().toUpperCase();

    if (couponCode.isEmpty) {
      _showErrorSnackbar('Please enter a coupon code');
      return;
    }

    _isCouponLoading.value = true;

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Check if coupon exists
    if (!_demoValidCoupons.containsKey(couponCode)) {
      _showErrorSnackbar('Invalid coupon code. Please check and try again.');
      _isCouponLoading.value = false;
      return;
    }

    final couponData = _demoValidCoupons[couponCode]!;
    final double minOrderAmount = couponData['minOrder'];

    // Calculate current cart total
    final double currentCartTotal = _calculateCartTotal();

    // Check minimum order requirement
    if (currentCartTotal < minOrderAmount) {
      _showErrorSnackbar(
          'Minimum order of ₹${minOrderAmount.toStringAsFixed(0)} required for this coupon'
      );
      _isCouponLoading.value = false;
      return;
    }

    // Calculate discount amount
    double discountAmount = 0.0;
    if (couponData['type'] == 'percentage') {
      discountAmount = (currentCartTotal * couponData['discount']) / 100;
      discountAmount = discountAmount > couponData['maxDiscount']
          ? couponData['maxDiscount']
          : discountAmount;
    } else {
      discountAmount = couponData['discount'];
    }

    // Apply coupon
    _couponDiscount.value = discountAmount;
    _isCouponApplied.value = true;
    _appliedCouponCode.value = couponCode;
    _couponCode.value = couponCode;
    _couponType.value = couponData['type'];
    _couponDescription.value = couponData['description'];

    _showSuccessSnackbar(
        'Coupon Applied! 🎉',
        'You saved ₹${discountAmount.toStringAsFixed(0)} with $couponCode'
    );

    _isCouponLoading.value = false;
  }

  // ✅ Remove coupon with confirmation
  void _removeCoupon() {
    _isCouponApplied.value = false;
    _couponDiscount.value = 0.0;
    _appliedCouponCode.value = '';
    _couponCode.value = '';
    _couponType.value = '';
    _couponDescription.value = '';
    _couponController.clear();

    Get.snackbar(
      'Coupon Removed',
      'Your coupon discount has been removed from the order',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.textMedium.withOpacity(0.9),
      colorText: AppColors.white,
      icon: const Icon(Icons.info_outline, color: AppColors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  // ✅ Enhanced Error Snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Invalid Coupon',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.danger.withOpacity(0.9),
      colorText: AppColors.white,
      icon: const Icon(Icons.error_outline, color: AppColors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  // ✅ Enhanced Success Snackbar
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.success.withOpacity(0.9),
      colorText: AppColors.white,
      icon: const Icon(Icons.check_circle_outline, color: AppColors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  // ✅ PREMIUM: Complete Coupon Section Widget
// ✅ MINIMALISTIC: Compact Coupon Section Widget
  Widget _buildCouponSection(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCouponApplied.value
                ? AppColors.success.withOpacity(0.2)
                : AppColors.neutralBackground,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isCouponApplied.value
            ? _buildAppliedCouponMinimal(textTheme)
            : _buildCouponInputMinimal(textTheme),
      );
    });
  }

// ✅ Minimalistic Applied Coupon
  Widget _buildAppliedCouponMinimal(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_offer,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _appliedCouponCode.value,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "-₹${_couponDiscount.value.toStringAsFixed(0)}",
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Coupon applied successfully",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Remove Button
          GestureDetector(
            onTap: _removeCoupon,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close,
                color: AppColors.textMedium,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ Minimalistic Coupon Input
  Widget _buildCouponInputMinimal(TextTheme textTheme) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Have a coupon?",
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),

        // Input Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              // Input Field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.neutralBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.neutralBackground,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter code",
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _applyCoupon(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Apply Button
              GestureDetector(
                onTap: _isCouponLoading.value ? null : _applyCoupon,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _isCouponLoading.value
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      "Apply",
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Available Coupons (Compact)
        if (_demoValidCoupons.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.neutralBackground.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Available offers",
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _demoValidCoupons.entries.take(4).map((entry) {
                    return _buildCompactCouponChip(entry.key, entry.value, textTheme);
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

// ✅ Compact Coupon Chip
  Widget _buildCompactCouponChip(
      String code,
      Map<String, dynamic> couponData,
      TextTheme textTheme
      ) {
    final currentTotal = _calculateCartTotal();
    final isUsable = currentTotal >= couponData['minOrder'];

    return GestureDetector(
      onTap: () {
        if (isUsable) {
          _couponController.text = code;
          _applyCoupon();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUsable
              ? AppColors.primaryPurple.withOpacity(0.1)
              : AppColors.textLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isUsable
                ? AppColors.primaryPurple.withOpacity(0.2)
                : AppColors.textLight.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: textTheme.labelSmall?.copyWith(
                color: isUsable
                    ? AppColors.primaryPurple
                    : AppColors.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              couponData['type'] == 'percentage'
                  ? "${couponData['discount'].toInt()}%"
                  : "₹${couponData['discount'].toInt()}",
              style: textTheme.labelSmall?.copyWith(
                color: isUsable
                    ? AppColors.primaryPurple
                    : AppColors.textLight,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ✅ Method to get related products based on cart items' categories
  List<ProductModel> _getRelatedProducts(List<Map<String, dynamic>> cartProductsWithDetails) {
    // Get all products from ProductController
    final allProducts = productController.allProducts;

    // Extract unique category IDs from cart items
    final Set<String> cartCategoryIds = {};
    for (var entry in cartProductsWithDetails) {
      final ProductModel product = entry['product'] as ProductModel;
      if (product.categoryId.isNotEmpty) {
        cartCategoryIds.add(product.categoryId);
      }
    }

    // Get cart product IDs to exclude them from suggestions
    final Set<String> cartProductIds = {};
    for (var entry in cartProductsWithDetails) {
      final ProductModel product = entry['product'] as ProductModel;
      cartProductIds.add(product.id);
    }

    // Filter products that belong to same categories but aren't in cart
    final relatedProducts = allProducts.where((product) {
      // Must be from same category
      final bool isSameCategory = cartCategoryIds.contains(product.categoryId);

      // Must not be in cart already
      final bool isNotInCart = !cartProductIds.contains(product.id);

      // Must be active and have stock
      final bool isAvailable = product.active &&
          product.variants.entries.any((variant) => variant.value > 0);

      return isSameCategory && isNotInCart && isAvailable;
    }).toList();

    // Shuffle and limit to reasonable number for suggestions
    relatedProducts.shuffle();
    return relatedProducts.take(10).toList(); // Show max 10 related products
  }

  // Method to navigate to payment method selection screen
  void _navigateToPaymentMethodSelection(BuildContext context) async {
    final String? result = await Get.to<String?>(
          () => PaymentMethodSelectionScreen(),
      fullscreenDialog: true,
      transition: Transition.rightToLeft,
    );

    if (result != null && result.isNotEmpty) {
      _selectedPaymentMethod.value = result;
    }
  }

  // ✅ NEW: Enhanced place order method with automatic navigation
  void _handlePlaceOrder(BuildContext context) async {
    final isAddressSelected = addressController.selectedAddress.value != null;
    final isCartEmpty = cartController.cartItems.isEmpty;
    final isPaymentMethodSelected = _selectedPaymentMethod.value.isNotEmpty;

    // ✅ Silent validation with automatic navigation to fix issues
    if (!isAddressSelected) {
      // Automatically navigate to address page
      Get.to(() => AddressPage());
      return;
    }

    if (isCartEmpty) {
      // Navigate back since cart is empty
      Get.back();
      return;
    }

    if (!isPaymentMethodSelected) {
      // Automatically navigate to payment method selection
      _navigateToPaymentMethodSelection(context);
      return;
    }

    // ✅ All validations passed, proceed with order
    orderController.isLoading.value = true;

    if (_selectedPaymentMethod.value == 'COD') {
      await orderController.placeOrder(method: 'COD');
    } else if (_selectedPaymentMethod.value == 'Online') {
      // ✅ Keep only positive feedback for online payment
      Get.snackbar(
        'Online Payment',
        'Initiating secure payment...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryPurple.withOpacity(0.8),
        colorText: AppColors.white,
        icon: const Icon(Icons.credit_card_outlined, color: AppColors.white),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        animationDuration: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 2),
      );
      await orderController.placeOrder(method: 'Online');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color blinkitBackground = AppColors.neutralBackground;

    return Scaffold(
      backgroundColor: blinkitBackground,
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final cartItems = cartController.cartItems;

        final cartProductsWithDetails = cartItems.map((item) {
          final productData = item['productId'];
          final product = productData is Map<String, dynamic>
              ? ProductModel.fromJson(productData as Map<String, dynamic>)
              : ProductModel(
            id: '',
            name: 'Fallback Product',
            fullName: 'Fallback Product Full Name',
            slug: 'fallback-product',
            description: 'This is a fallback product.',
            active: false,
            newArrival: false,
            liked: false,
            bestSeller: false,
            recommended: false,
            sellingPrice: [],
            categoryId: '',
            stockIds: [],
            orderIds: [],
            groupIds: [],
            totalStock: 0,
            variants: {},
            images: [],
            descriptionPoints: [],
            keyInformation: [],
          );
          final quantity = item['quantity'] as int? ?? 1;
          final variantName = item['variantName'] as String? ?? 'Default';
          return {
            'product': product,
            'quantity': quantity,
            'variantName': variantName
          };
        }).toList();

        double itemTotal = cartProductsWithDetails.fold(0.0, (sum, entry) {
          final ProductModel product = entry['product'] as ProductModel;
          final int quantity = entry['quantity'] as int;
          double itemPrice = 0.0;
          if (product.sellingPrice.isNotEmpty &&
              product.sellingPrice[0].price != null) {
            itemPrice = product.sellingPrice[0].price!.toDouble();
          }
          return sum + itemPrice * quantity;
        });

        double deliveryCharge = itemTotal > 0 ? 40.0 : 0.0;
        double gstCharge = 0.0;

        // ✅ Get related products based on cart items' categories
        final relatedProducts = _getRelatedProducts(cartProductsWithDetails);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cart Items Section
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textDark.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cart Items (${cartProductsWithDetails.length})",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartProductsWithDetails.length,
                      itemBuilder: (context, index) {
                        final entry = cartProductsWithDetails[index];
                        final product = entry['product'] as ProductModel;
                        final quantity = entry['quantity'] as int;
                        final variantName = entry['variantName'].toString();
                        return CartItemTile(
                          product: product,
                          quantity: quantity,
                          variantName: variantName,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ✅ NEW: Premium Coupon Section
              _buildCouponSection(context),
              const SizedBox(height: 20),

              // Bill Details Section (Updated to include coupon discount)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textDark.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() => BillSection(
                  itemTotal: itemTotal.toInt(),
                  deliveryCharge: deliveryCharge.toInt(),
                  couponDiscount: _couponDiscount.value.toInt(),
                )),
              ),

              const SizedBox(height: 32),

              // ✅ Updated "You might also like" section with related products
              if (relatedProducts.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      "You might also like",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${relatedProducts.length}',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: relatedProducts.length,
                    itemBuilder: (context, index) {
                      final relatedProduct = relatedProducts[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: SizedBox(
                          width: 160,
                          child: AllProductGridCard(
                            product: relatedProduct,
                            heroTag: 'product_image_checkout_related_${relatedProduct.id}_$index',
                            onTap: (tappedProduct) {
                              Get.to(
                                    () => ProductPage(
                                  product: tappedProduct,
                                  heroTag: 'product_image_checkout_related_${tappedProduct.id}_$index',
                                ),
                                transition: Transition.fadeIn,
                                duration: const Duration(milliseconds: 300),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (cartProductsWithDetails.isNotEmpty) ...[
                // ✅ Fallback: Show message when no related products found
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neutralBackground),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primaryPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No related products found',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore more products after placing your order!',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildDynamicBottomAppBar(context),
    );
  }

  Widget _buildDynamicBottomAppBar(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 230,
      width: double.infinity,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address Section (unchanged)
            Obx(() {
              final selected = addressController.selectedAddress.value;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_pin,
                    color: selected != null ? AppColors.success : AppColors.textLight,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?.label ?? 'No Address Selected',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected != null ? AppColors.textDark : AppColors.textLight,
                          ),
                        ),
                        if (selected != null) ...[
                          Text(
                            "${selected.street}, ${selected.city},",
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${selected.state} - ${selected.pinCode}",
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
                          ),
                        ] else
                          Text(
                            "Please add or select an address for delivery.",
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.to(() => AddressPage());
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      selected != null ? "Change" : "Add/Select",
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.neutralBackground),
            const SizedBox(height: 16),

            // Pay Using & Place Order Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Obx(() {
                    return InkWell(
                      onTap: orderController.isLoading.value
                          ? null
                          : () => _navigateToPaymentMethodSelection(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: orderController.isLoading.value
                              ? AppColors.success.withOpacity(0.6)
                              : AppColors.success,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            orderController.isLoading.value
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.white, strokeWidth: 2),
                            )
                                : const Icon(Icons.account_balance_wallet_rounded,
                                color: AppColors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              orderController.isLoading.value
                                  ? "Processing..."
                                  : (_selectedPaymentMethod.value.isEmpty ? "Pay Using" : _selectedPaymentMethod.value),
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 3,
                  child: Obx(() {
                    double subTotal = cartController.cartItems.fold(0.0, (sum, item) {
                      final productData = item['productId'];
                      final product = productData is Map<String, dynamic>
                          ? ProductModel.fromJson(productData)
                          : ProductModel(
                          id: '',
                          name: '',
                          fullName: '',
                          slug: '',
                          description: '',
                          images: [],
                          sellingPrice: [],
                          variants: {},
                          active: false,
                          newArrival: false,
                          liked: false,
                          bestSeller: false,
                          recommended: false,
                          categoryId: '',
                          stockIds: [],
                          orderIds: [],
                          groupIds: [],
                          totalStock: 0,
                          descriptionPoints: [],
                          keyInformation: []
                      );
                      final quantity = item['quantity'] ?? 1;
                      double itemPrice = 0.0;
                      if (product.sellingPrice.isNotEmpty &&
                          product.sellingPrice[0].price != null) {
                        itemPrice = product.sellingPrice[0].price!.toDouble();
                      }
                      return sum + itemPrice * quantity;
                    });

                    final deliveryCharge = subTotal > 0 ? 40.0 : 0.0;
                    final gstCharge = 0.0;
                    // ✅ Apply coupon discount to final total
                    final displayTotal = (subTotal + deliveryCharge + gstCharge) - _couponDiscount.value;

                    final isAddressSelected = addressController.selectedAddress.value != null;
                    final isCartEmpty = cartController.cartItems.isEmpty;
                    final isPaymentMethodSelected = _selectedPaymentMethod.value.isNotEmpty;

                    // ✅ FIXED: Only disable when loading OR cart is empty
                    // Allow clicking when address or payment method is missing (for auto-navigation)
                    final bool isPlaceOrderDisabled = orderController.isLoading.value || isCartEmpty;

                    return InkWell(
                      // ✅ FIXED: Always allow tap unless loading or cart empty
                      onTap: isPlaceOrderDisabled ? null : () => _handlePlaceOrder(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isPlaceOrderDisabled
                              ? AppColors.primaryPurple.withOpacity(0.6)
                              : AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "₹${displayTotal.toStringAsFixed(0)}",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // ✅ Show savings indicator when coupon is applied
                                      if (_isCouponApplied.value) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.local_offer,
                                          color: AppColors.white.withOpacity(0.8),
                                          size: 12,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _isCouponApplied.value
                                        ? "Saved ₹${_couponDiscount.value.toStringAsFixed(0)}"
                                        : "Total",
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (orderController.isLoading.value)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: AppColors.white, strokeWidth: 2),
                                    )
                                  else
                                    Text(
                                      "Place Order",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  if (!orderController.isLoading.value)
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: AppColors.white, size: 18),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
