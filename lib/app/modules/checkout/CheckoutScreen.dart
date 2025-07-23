import 'package:flutter/cupertino.dart'; // For iOS-style icons, if needed
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
import '../../data/AddressModel.dart';
import '../../data/product_model.dart';
import '../../themes/app_theme.dart';
import '../home/widgets/ProductCard.dart'; // Import your AppTheme and AppColors
// Import your new screen

class CheckoutScreen extends StatelessWidget {
  CheckoutScreen({Key? key}) : super(key: key);

  final cartController = Get.find<CartController>();
  final addressController = Get.find<AddressController>();
  final orderController = Get.find<OrderController>();

  // Add an RxString to hold the selected payment method
  final RxString _selectedPaymentMethod = ''.obs;

  // NEW: Method to navigate to payment method selection screen
  void _navigateToPaymentMethodSelection(BuildContext context) async {
    final TextTheme textTheme = Theme.of(context).textTheme; // Access TextTheme

    // Navigate and await the result (the selected payment method string)
    final String? result = await Get.to<String?>(
          () => PaymentMethodSelectionScreen(
        selectedPaymentMethod: _selectedPaymentMethod, // Pass the RxString
        orderController: orderController, // Pass the controller
      ),
      fullscreenDialog: true, // Makes it a full screen modal
      transition: Transition.rightToLeft, // Smooth transition
    );

    // If a method was selected and returned
    if (result != null && result.isNotEmpty) {
      _selectedPaymentMethod.value = result; // Update the selected method
      // You can now immediately trigger the placeOrder logic here if desired,
      // or rely on the "Place Order" button being enabled.
      // For this setup, we'll wait for the "Place Order" button.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access TextTheme and AppColors for consistent theming
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Based on Blinkit, the background is a very light grey or off-white
    final Color blinkitBackground = AppColors.neutralBackground;

    return Scaffold(
      backgroundColor: blinkitBackground, // Consistent light background
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: textTheme.titleLarge?.copyWith( // Using titleLarge for AppBar title
            fontWeight: FontWeight.w600, // Semi-bold for prominence
            color: AppColors.textDark, // Dark text color
          ),
        ),
        backgroundColor: AppColors.white, // White AppBar background
        foregroundColor: AppColors.textDark, // Dark icons/text
        elevation: 0.5, // Subtle elevation for app bar
        // Back button styling (default should be fine with foregroundColor)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded), // iOS style back icon
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
            images: [], descriptionPoints: [], keyInformation: [],
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

        // Delivery charge logic from original
        double deliveryCharge = itemTotal > 0 ? 40.0 : 0.0;
        double gstCharge = 0.0; // Currently set to 0, as per your previous code

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted padding
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
                padding: const EdgeInsets.all(16), // Padding inside the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cart Items (${cartProductsWithDetails.length})",
                      style: textTheme.titleMedium?.copyWith( // Consistent title style
                        fontWeight: FontWeight.w700, // Make it bolder
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Use ListView.builder for potentially many items
                    ListView.builder(
                      shrinkWrap: true, // Crucial for nested ListViews
                      physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
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
              const SizedBox(height: 20), // Space between cart items and bill section

              // Bill Details Section
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
                  itemTotal: itemTotal.toInt(),
                  deliveryCharge: deliveryCharge.toInt(),
                  // gstCharge: gstCharge.toInt(), // Pass gstCharge if you re-enable it
                ),
              ),

              const SizedBox(height: 32), // Space before suggested products

              // You might also like section
              Text(
                "You might also like",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, // Bolder title
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280, // Increased height for suggested products to give them more space
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cartProductsWithDetails.length, // Using cart products as dummy data for suggestions
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 14), // Space between cards
                      child: ProductCards(
                        product: cartProductsWithDetails[index]['product'] as ProductModel,
                        // It is CRUCIAL to pass a unique heroTag here to avoid "multiple heroes" error.
                        // The tag should be unique across all ProductCards visible on screen simultaneously.
                        heroTag: 'product_image_checkout_suggested_${cartProductsWithDetails[index]['product']}_$index', // Example unique tag
                        onTap: (tappedProduct) {
                          // You can define specific navigation logic here if needed,
                          // or let ProductCards handle it using its internal Get.to() as configured.
                          // If ProductCards handles navigation, ensure it passes the correct heroTag.
                          // Example of explicit navigation:
                           Get.to(
                             () => ProductPage(
                               product: tappedProduct,
                               heroTag: 'product_image_checkout_suggested_${tappedProduct.id}_$index',
                             ),
                             transition: Transition.fadeIn,
                             duration: const Duration(milliseconds: 300),
                           );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 100), // Ensures content doesn't get cut off by bottom bar
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildDynamicBottomAppBar(context), // Pass context to access theme
    );
  }

  // NOTE: _buildPaymentOption is ONLY needed if you use it somewhere else.
  // If it was just for the dialog, it should now live in PaymentMethodSelectionScreen.
  // I've removed it from here as it's no longer used in CheckoutScreen directly.
  // If you re-introduce it elsewhere, ensure its usage context is appropriate.


  // Refactored _buildDynamicBottomAppBar
  Widget _buildDynamicBottomAppBar(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme; // Access TextTheme

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white, // White background for bottom bar
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.1), // More subtle shadow
            blurRadius: 15,
            offset: const Offset(0, -5), // Slightly higher offset
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 230,
      width: double.infinity,
      child: SafeArea(
        top: false, // Don't extend into safe area at the top
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, // Slightly wider drag handle
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralBackground, // Light grey drag handle
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16), // More space after handle

            // Address Section
            Obx(() {
              final selected = addressController.selectedAddress.value;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_pin,
                    color: selected != null ? AppColors.success : AppColors.textLight, // Green for selected, light grey if not
                    size: 24, // Slightly smaller icon
                  ),
                  const SizedBox(width: 10), // Reduced space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?.label ?? 'No Address Selected',
                          style: textTheme.bodyLarge?.copyWith( // BodyLarge for address label
                            fontWeight: FontWeight.w600,
                            color: selected != null ? AppColors.textDark : AppColors.textLight,
                          ),
                        ),
                        if (selected != null) ...[
                          Text(
                            "${selected.street}, ${selected.city},",
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium), // bodySmall for address details
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
                      padding: EdgeInsets.zero, // Remove default padding
                      minimumSize: Size.zero, // Remove default min size
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink tap area
                    ),
                    child: Text(
                      selected != null ? "Change" : "Add/Select",
                      style: textTheme.labelLarge?.copyWith( // labelLarge for button
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16), // Space before divider
            const Divider(height: 1, color: AppColors.neutralBackground), // Lighter divider
            const SizedBox(height: 16), // Space after divider

            // Pay Using & Place Order Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Obx(() {
                    return InkWell(
                      // UPDATED: Call the navigation method
                      onTap: orderController.isLoading.value
                          ? null
                          : () => _navigateToPaymentMethodSelection(context), // Now navigates to a screen
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 52, // Slightly taller button
                        decoration: BoxDecoration(
                          color: orderController.isLoading.value
                              ? AppColors.success.withOpacity(0.6) // Green for pay using button, lighter when loading
                              : AppColors.success, // Solid green
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [ // Add subtle shadow for consistency
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
                                  : (_selectedPaymentMethod.value.isEmpty ? "Pay Using" : _selectedPaymentMethod.value), // Show selected method
                              style: textTheme.bodyMedium?.copyWith( // labelLarge for button text
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
                          totalStock: 0, descriptionPoints: [], keyInformation: []);
                      final quantity = item['quantity'] ?? 1;
                      double itemPrice = 0.0;
                      if (product.sellingPrice.isNotEmpty &&
                          product.sellingPrice[0].price != null) {
                        itemPrice = product.sellingPrice[0].price!.toDouble();
                      }
                      return sum + itemPrice * quantity;
                    });

                    final deliveryCharge = subTotal > 0 ? 40.0 : 0.0;
                    final gstCharge = 0.0; // Still 0
                    final displayTotal = subTotal + deliveryCharge + gstCharge; // Include gstCharge for total even if 0

                    final isAddressSelected = addressController.selectedAddress.value != null;
                    final isCartEmpty = cartController.cartItems.isEmpty;
                    final isPaymentMethodSelected = _selectedPaymentMethod.value.isNotEmpty;

                    // Determine if the button should be disabled
                    final bool isPlaceOrderDisabled = orderController.isLoading.value ||
                        !isAddressSelected ||
                        isCartEmpty ||
                        !isPaymentMethodSelected;

                    return InkWell(
                      onTap: isPlaceOrderDisabled
                          ? null
                          : () async {
                        // Check all conditions again before placing order
                        if (!isAddressSelected) {
                          Get.snackbar(
                            'Address Required',
                            'Please select a delivery address.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.danger.withOpacity(0.8), // Red snackbar
                            colorText: AppColors.white,
                            icon: const Icon(Icons.location_on, color: AppColors.white),
                            margin: const EdgeInsets.all(10),
                            borderRadius: 10,
                            animationDuration: const Duration(milliseconds: 300),
                            duration: const Duration(seconds: 3),
                          );
                          return;
                        }

                        if (isCartEmpty) {
                          Get.snackbar(
                            'Cart Empty',
                            'Your cart is empty. Please add items before placing an order.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.danger.withOpacity(0.8),
                            colorText: AppColors.white,
                            icon: const Icon(Icons.shopping_cart, color: AppColors.white),
                            margin: const EdgeInsets.all(10),
                            borderRadius: 10,
                            animationDuration: const Duration(milliseconds: 300),
                            duration: const Duration(seconds: 3),
                          );
                          return;
                        }

                        if (!isPaymentMethodSelected) {
                          Get.snackbar(
                            'Payment Method Required',
                            'Please select a payment method before placing your order.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.danger.withOpacity(0.8),
                            colorText: AppColors.white,
                            icon: const Icon(Icons.payment, color: AppColors.white),
                            margin: const EdgeInsets.all(10),
                            borderRadius: 10,
                            animationDuration: const Duration(milliseconds: 300),
                            duration: const Duration(seconds: 3),
                          );
                          // Trigger navigation to payment method selection if not selected
                          _navigateToPaymentMethodSelection(context);
                          return;
                        }

                        // If all checks pass, proceed with placing the order
                        if (_selectedPaymentMethod.value.isEmpty) {
                          Get.snackbar(
                            'Payment Method Required',
                            'Please select a payment method before placing your order.',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.redAccent,
                            colorText: AppColors.white,
                            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.white),
                            margin: const EdgeInsets.all(10),
                            borderRadius: 10,
                            duration: const Duration(seconds: 3),
                            animationDuration: const Duration(milliseconds: 300),
                          );
                          return;
                        }

                        orderController.isLoading.value = true;

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
                            animationDuration: const Duration(milliseconds: 300),
                            duration: const Duration(seconds: 2),
                          );
                          await orderController.placeOrder(method: 'Online');
                        }

                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 52, // Match height of 'Pay Using' button
                        decoration: BoxDecoration(
                          color: isPlaceOrderDisabled
                              ? AppColors.primaryPurple.withOpacity(0.6) // Lighter purple when disabled
                              : AppColors.primaryPurple, // Solid purple
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [ // Add subtle shadow for consistency
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12), // Adjusted horizontal padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "₹${displayTotal.toStringAsFixed(0)}",
                                    style: textTheme.bodyMedium?.copyWith( // TitleMedium for total amount
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Total",
                                    style: textTheme.labelSmall?.copyWith( // labelSmall for "Total" label
                                      color: AppColors.white.withOpacity(0.8), // Slightly transparent white
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
                                      style: textTheme.bodyMedium?.copyWith( // labelLarge for "Place Order" text
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

// REMOVED: _showPaymentMethodSelectionDialog method is now removed from CheckoutScreen
// as it has been replaced by navigation to PaymentMethodSelectionScreen.
}