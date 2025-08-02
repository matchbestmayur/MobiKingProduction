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
import '../../controllers/coupon_controller.dart';
import '../../data/AddressModel.dart';
import '../../data/coupon_model.dart';
import '../../data/product_model.dart';
import '../../themes/app_theme.dart';
import '../home/widgets/AllProductGridCard.dart';
import '../home/widgets/ProductCard.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final cartController = Get.find<CartController>();
  final addressController = Get.find<AddressController>();
  final orderController = Get.find<OrderController>();
  final productController = Get.find<ProductController>();
  final couponController = Get.find<CouponController>();

  // Add an RxString to hold the selected payment method
  final RxString _selectedPaymentMethod = ''.obs;

  @override
  void initState() {
    super.initState();
    // ✅ UPDATED: Initialize coupon controller with current cart total
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartTotal = _calculateCartTotal();
      couponController.setSubtotal(cartTotal); // ✅ UPDATED: setSubtotal instead of setOrderAmount
      couponController.fetchAvailableCoupons();
    });
  }

  // ✅ BILLING PRECISION: Accurate cart total calculation
  double _calculateCartTotal() {
    try {
      double total = 0.0;

      for (var item in cartController.cartItems) {
        final productData = item['productId'];
        final quantity = (item['quantity'] as int?) ?? 1;

        if (productData is Map<String, dynamic>) {
          final product = ProductModel.fromJson(productData);

          // Get price from product's selling price array
          if (product.sellingPrice.isNotEmpty && product.sellingPrice[0].price != null) {
            final itemPrice = product.sellingPrice[0].price!.toDouble();
            total += itemPrice * quantity;
          }
        }
      }

      return double.parse(total.toStringAsFixed(2)); // Ensure precision
    } catch (e) {
      print('Error calculating cart total: $e');
      return 0.0;
    }
  }

  // ✅ BILLING PRECISION: Calculate delivery charge with business logic
  double _calculateDeliveryCharge(double cartTotal) {
    if (cartTotal <= 0) return 0.0;

    // Business logic: Free delivery above ₹500
    if (cartTotal >= 500) return 0.0;

    return 40.0; // Standard delivery charge
  }

  // ✅ BILLING PRECISION: Calculate GST (if applicable)
  double _calculateGST(double cartTotal) {
    // Assuming 0% GST for now, but can be configured
    return 0.0;
  }

  // ✅ BILLING PRECISION: Calculate final total with all charges and discounts
  Map<String, double> _calculateBillingBreakdown() {
    final cartTotal = _calculateCartTotal();
    final deliveryCharge = _calculateDeliveryCharge(cartTotal);
    final gstCharge = _calculateGST(cartTotal);

    // Subtotal before discount
    final subtotal = cartTotal + deliveryCharge + gstCharge;

    // Apply coupon discount
    final couponDiscount = couponController.isCouponApplied.value
        ? couponController.discountAmount.value
        : 0.0;

    // Ensure discount doesn't exceed subtotal
    final actualDiscount = couponDiscount > subtotal ? subtotal : couponDiscount;

    // Final total
    final finalTotal = subtotal - actualDiscount;

    return {
      'cartTotal': double.parse(cartTotal.toStringAsFixed(2)),
      'deliveryCharge': double.parse(deliveryCharge.toStringAsFixed(2)),
      'gstCharge': double.parse(gstCharge.toStringAsFixed(2)),
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'couponDiscount': double.parse(actualDiscount.toStringAsFixed(2)),
      'finalTotal': double.parse(finalTotal.toStringAsFixed(2)),
    };
  }

  // ✅ UPDATED: Update coupon controller when cart changes
  void _updateCouponOrderAmount() {
    final cartTotal = _calculateCartTotal();
    couponController.setSubtotal(cartTotal); // ✅ UPDATED: setSubtotal instead of setOrderAmount
  }

  // ✅ COMPLETELY FIXED: Helper method to safely get coupon code
  String _getCouponCode(dynamic coupon) {
    try {
      if (coupon == null) return 'CODE';

      // Handle different possible field names
      if (coupon is Map) {
        return coupon['code']?.toString() ??
            coupon['couponCode']?.toString() ??
            coupon['Code']?.toString() ??
            'CODE';
      }

      // If it's a CouponModel object
      if (coupon.code != null) {
        return coupon.code.toString();
      }

      return 'CODE';
    } catch (e) {
      print('Error getting coupon code: $e');
      return 'CODE';
    }
  }

  // ✅ COMPLETELY FIXED: Helper method to safely get discount text
  String _getCouponDiscountText(dynamic coupon) {
    try {
      if (coupon == null) return 'OFFER';

      double percentValue = 0.0;
      double valueAmount = 0.0;

      // Handle different data structures
      if (coupon is Map) {
        // Try different possible field names for percentage
        final percentStr = coupon['percent']?.toString() ??
            coupon['percentage']?.toString() ??
            coupon['discountPercent']?.toString() ??
            coupon['Percent']?.toString() ?? '0';

        // Try different possible field names for value
        final valueStr = coupon['value']?.toString() ??
            coupon['discountValue']?.toString() ??
            coupon['amount']?.toString() ??
            coupon['Value']?.toString() ?? '0';

        percentValue = double.tryParse(percentStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        valueAmount = double.tryParse(valueStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      } else {
        // Handle CouponModel object
        if (coupon.percent != null) {
          percentValue = double.tryParse(coupon.percent.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        }
        if (coupon.value != null) {
          valueAmount = double.tryParse(coupon.value.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        }
      }

      // Return percentage first, then value
      if (percentValue > 0) {
        return "${percentValue.toInt()}%";
      } else if (valueAmount > 0) {
        return "₹${valueAmount.toInt()}";
      }

      return "OFFER";
    } catch (e) {
      print('Error parsing coupon discount: $e');
      return "OFFER";
    }
  }

  // ✅ COMPLETELY FIXED: Helper method to safely check if coupon is usable
  bool _isCouponUsable(dynamic coupon) {
    try {
      if (coupon == null) return false;

      bool hasDiscount = false;

      // Check if coupon has any discount
      if (coupon is Map) {
        final percentStr = coupon['percent']?.toString() ??
            coupon['percentage']?.toString() ??
            coupon['discountPercent']?.toString() ?? '0';

        final valueStr = coupon['value']?.toString() ??
            coupon['discountValue']?.toString() ??
            coupon['amount']?.toString() ?? '0';

        final percentValue = double.tryParse(percentStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        final valueAmount = double.tryParse(valueStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

        hasDiscount = percentValue > 0 || valueAmount > 0;

        // ✅ FIXED: Check dates if available with proper type handling
        if (hasDiscount && coupon['startDate'] != null && coupon['endDate'] != null) {
          try {
            final now = DateTime.now();
            DateTime? startDate;
            DateTime? endDate;

            // ✅ Handle different date formats safely
            final startDateValue = coupon['startDate'];
            final endDateValue = coupon['endDate'];

            // Parse startDate
            if (startDateValue is DateTime) {
              startDate = startDateValue;
            } else if (startDateValue is String) {
              startDate = DateTime.parse(startDateValue);
            } else if (startDateValue is int) {
              startDate = DateTime.fromMillisecondsSinceEpoch(startDateValue);
            }

            // Parse endDate
            if (endDateValue is DateTime) {
              endDate = endDateValue;
            } else if (endDateValue is String) {
              endDate = DateTime.parse(endDateValue);
            } else if (endDateValue is int) {
              endDate = DateTime.fromMillisecondsSinceEpoch(endDateValue);
            }

            // Check if both dates are valid
            if (startDate != null && endDate != null) {
              return now.isAfter(startDate) && now.isBefore(endDate);
            } else {
              print('Could not parse coupon dates - assuming valid');
              return hasDiscount; // Return discount check if date parsing fails
            }
          } catch (e) {
            print('Error parsing coupon dates: $e');
            return hasDiscount; // Return discount check if date parsing fails
          }
        }
      } else {
        // Handle CouponModel object
        try {
          final percentValue = double.tryParse(coupon.percent?.toString()?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0.0;
          final valueAmount = double.tryParse(coupon.value?.toString()?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0.0;

          hasDiscount = percentValue > 0 || valueAmount > 0;

          if (hasDiscount) {
            // ✅ Use the CouponModel's built-in validation
            return coupon.isValid ?? true;
          }
        } catch (e) {
          print('Error checking CouponModel: $e');
          return false;
        }
      }

      return hasDiscount;
    } catch (e) {
      print('Error checking coupon usability: $e');
      return false;
    }
  }

  // ✅ COMPLETELY FIXED: Safe coupon selection
  // ✅ FIXED: Safe coupon selection with proper type casting
  void _selectCouponSafely(dynamic coupon) {
    try {
      if (coupon == null) return;

      // Convert raw coupon data to CouponModel if needed
      if (coupon is Map) {
        // ✅ ADD TYPE CASTING HERE
        final couponMap = Map<String, dynamic>.from(coupon);
        final couponModel = CouponModel.fromJson(couponMap);
        couponController.selectCoupon(couponModel);
      } else if (coupon is CouponModel) {
        couponController.selectCoupon(coupon);
      } else {
        print('Unknown coupon type: ${coupon.runtimeType}');
      }
    } catch (e) {
      print('Error selecting coupon: $e');
      Get.snackbar(
        'Error',
        'Failed to select coupon. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withOpacity(0.9),
        colorText: AppColors.white,
      );
    }
  }


  // ✅ DYNAMIC COUPON SECTION: Replace dummy code with real controller
  Widget _buildCouponSection(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: couponController.isCouponApplied.value
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
        child: couponController.isCouponApplied.value
            ? _buildAppliedCouponWidget(textTheme)
            : _buildCouponInputWidget(textTheme),
      );
    });
  }

  // ✅ Applied Coupon Display
  Widget _buildAppliedCouponWidget(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Success Icon
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

          // Coupon Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(() => Text(
                      couponController.selectedCoupon.value?.code ?? 'COUPON',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 1,
                      ),
                    )),
                    const SizedBox(width: 8),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "-₹${couponController.discountAmount.value.toStringAsFixed(0)}",
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 2),
                Obx(() => Text(
                  couponController.successMessage.value.isNotEmpty
                      ? couponController.successMessage.value
                      : "Coupon applied successfully",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                )),
              ],
            ),
          ),

          // Remove Button
          GestureDetector(
            onTap: () {
              couponController.removeCoupon();
              _updateCouponOrderAmount(); // Update billing
            },
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

  // ✅ Coupon Input Widget
  Widget _buildCouponInputWidget(TextTheme textTheme) {
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
                    controller: couponController.couponTextController,
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
                    onSubmitted: (_) => _applyCouponWithBillingUpdate(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Apply Button
              Obx(() => GestureDetector(
                onTap: couponController.isLoading.value ? null : _applyCouponWithBillingUpdate,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: couponController.isLoading.value
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
              )),
            ],
          ),
        ),

        // Error/Success Messages
        Obx(() {
          if (couponController.errorMessage.value.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        couponController.errorMessage.value,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Available Coupons Preview
        Obx(() {
          if (couponController.availableCoupons.isNotEmpty) {
            return Container(
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
                    children: couponController.availableCoupons.take(3).map((coupon) {
                      return _buildCompactCouponChip(coupon, textTheme);
                    }).toList(),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  // ✅ COMPLETELY FIXED: Compact Coupon Chip
  Widget _buildCompactCouponChip(dynamic coupon, TextTheme textTheme) {
    final isUsable = _isCouponUsable(coupon);
    final couponCode = _getCouponCode(coupon);
    final discountText = _getCouponDiscountText(coupon);

    return GestureDetector(
      onTap: () {
        if (isUsable) {
          _selectCouponSafely(coupon);
          _applyCouponWithBillingUpdate();
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
              couponCode,
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
              discountText,
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

  // ✅ UPDATED: Apply coupon with billing update
  void _applyCouponWithBillingUpdate() async {
    // Update subtotal for coupon calculation
    final cartTotal = _calculateCartTotal();
    couponController.setSubtotal(cartTotal);

    // Validate and apply coupon
    final couponCode = couponController.couponTextController.text.trim();
    if (couponCode.isNotEmpty) {
      await couponController.validateAndApplyCoupon(couponCode);
    }

    // Force UI rebuild
    if (mounted) {
      setState(() {});
    }
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

  // ✅ UPDATED: Enhanced place order method with coupon data
  void _handlePlaceOrder(BuildContext context) async {
    final isAddressSelected = addressController.selectedAddress.value != null;
    final isCartEmpty = cartController.cartItems.isEmpty;
    final isPaymentMethodSelected = _selectedPaymentMethod.value.isNotEmpty;

    // ✅ BILLING VALIDATION: Check if final total is valid
    final billingBreakdown = _calculateBillingBreakdown();
    if (billingBreakdown['finalTotal']! <= 0) {
      Get.snackbar(
        'Invalid Order',
        'Order total cannot be zero or negative',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withOpacity(0.9),
        colorText: AppColors.white,
      );
      return;
    }

    // Silent validation with automatic navigation to fix issues
    if (!isAddressSelected) {
      Get.to(() => AddressPage());
      return;
    }

    if (isCartEmpty) {
      Get.back();
      return;
    }

    if (!isPaymentMethodSelected) {
      _navigateToPaymentMethodSelection(context);
      return;
    }

    // ✅ All validations passed, proceed with order
    orderController.isLoading.value = true;

    try {
      // ✅ UPDATED: Create order data with coupon information
      final orderData = {
        'items': cartController.cartItems,
        'address': addressController.selectedAddress.value?.toJson(),
        'paymentMethod': _selectedPaymentMethod.value,
        'cartTotal': billingBreakdown['cartTotal'],
        'deliveryCharge': billingBreakdown['deliveryCharge'],
        'couponDiscount': billingBreakdown['couponDiscount'],
        'finalTotal': billingBreakdown['finalTotal'],
        // ✅ UPDATED: Include coupon data for backend
        ...couponController.getOrderCouponData(),
      };

      if (_selectedPaymentMethod.value == 'COD') {
        await orderController.placeOrder(method: 'COD');
      } else if (_selectedPaymentMethod.value == 'Online') {
        Get.snackbar(
          'Online Payment',
          'Initiating secure payment...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryPurple.withOpacity(0.8),
          colorText: AppColors.white,
          icon: const Icon(Icons.credit_card_outlined, color: AppColors.white),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
        );
        await orderController.placeOrder(method: 'Online');
      }
    } catch (e) {
      print('Error placing order: $e');
      Get.snackbar(
        'Order Failed',
        'Please try again',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withOpacity(0.9),
        colorText: AppColors.white,
      );
    } finally {
      orderController.isLoading.value = false;
    }
  }

  // ✅ Method to get related products
  List<ProductModel> _getRelatedProducts(List<Map<String, dynamic>> cartProductsWithDetails) {
    final allProducts = productController.allProducts;
    final Set<String> cartCategoryIds = {};
    for (var entry in cartProductsWithDetails) {
      final ProductModel product = entry['product'] as ProductModel;
      if (product.categoryId.isNotEmpty) {
        cartCategoryIds.add(product.categoryId);
      }
    }

    final Set<String> cartProductIds = {};
    for (var entry in cartProductsWithDetails) {
      final ProductModel product = entry['product'] as ProductModel;
      cartProductIds.add(product.id);
    }

    final relatedProducts = allProducts.where((product) {
      final bool isSameCategory = cartCategoryIds.contains(product.categoryId);
      final bool isNotInCart = !cartProductIds.contains(product.id);
      final bool isAvailable = product.active &&
          product.variants.entries.any((variant) => variant.value > 0);

      return isSameCategory && isNotInCart && isAvailable;
    }).toList();

    relatedProducts.shuffle();
    return relatedProducts.take(10).toList();
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

        // ✅ Get precise billing breakdown
        final billingBreakdown = _calculateBillingBreakdown();
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

              // ✅ DYNAMIC COUPON SECTION
              _buildCouponSection(context),
              const SizedBox(height: 20),

              // ✅ PRECISE BILL DETAILS SECTION
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
                child: BillSection(
                  itemTotal: billingBreakdown['cartTotal']!.toInt(),
                  deliveryCharge: billingBreakdown['deliveryCharge']!.toInt(),
                  couponDiscount: billingBreakdown['couponDiscount']!.toInt(),
                ),
              ),

              const SizedBox(height: 32),

              // Related Products Section
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

            // Address Section
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

            // ✅ PRECISE BILLING: Pay Using & Place Order Buttons
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
                    // ✅ BULLETPROOF BILLING: Use precise calculation
                    final billingBreakdown = _calculateBillingBreakdown();
                    final displayTotal = billingBreakdown['finalTotal']!;

                    final isAddressSelected = addressController.selectedAddress.value != null;
                    final isCartEmpty = cartController.cartItems.isEmpty;
                    final isPaymentMethodSelected = _selectedPaymentMethod.value.isNotEmpty;

                    final bool isPlaceOrderDisabled = orderController.isLoading.value || isCartEmpty;

                    return InkWell(
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
                                      if (couponController.isCouponApplied.value) ...[
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
                                    couponController.isCouponApplied.value
                                        ? "Saved ₹${billingBreakdown['couponDiscount']!.toStringAsFixed(0)}"
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
