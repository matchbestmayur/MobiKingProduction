import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
// Removed as AppTheme provides comprehensive text styles
// import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/modules/cart/widget/CartItemCard.dart';
import 'package:mobiking/app/modules/checkout/CheckoutScreen.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Import your AppTheme

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Ensure cart data is loaded after the frame is rendered,
      // which is useful if the cart data fetching is asynchronous.
      cartController.fetchAndLoadCartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the TextTheme from the current context to ensure consistency
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground, // Consistent background from AppTheme
      appBar: AppBar(
        leading: GestureDetector(
            onTap: (){
              Get.back();
            },
            child: Icon(Icons.arrow_back_ios, color: AppColors.textDark)),
        automaticallyImplyLeading: false,
        elevation: 0, // Flat app bar for a cleaner look
        backgroundColor: AppColors.white, // AppBar background often remains white or a light color
        title: Text(
          'My Cart',
          style: textTheme.titleLarge?.copyWith( // Using titleLarge for AppBar title for prominence
            color: AppColors.textDark, // Dark text color for contrast
            fontWeight: FontWeight.bold, // Make it bold for emphasis
          ),
        ),
        centerTitle: false, // Title aligned to the left
        iconTheme: const IconThemeData(color: AppColors.textDark), // Dark icons for clear visibility
      ),
      body: SafeArea(
        child: Obx(() {
          // If cart is empty, display a friendly message and a call to action
          if (cartController.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.textLight.withOpacity(0.6), // Subtle cart icon
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: textTheme.headlineSmall?.copyWith( // Clear, noticeable message
                      color: AppColors.textLight, // Lighter text for a softer look
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some delicious items to get started!',
                    style: textTheme.bodyMedium?.copyWith( // Supportive descriptive text
                      color: AppColors.textLight, // Lighter text
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Get.back(); // Navigate back to shopping
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple, // Main brand color for action button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 4, // Subtle shadow for button lift
                    ),
                    child: Text(
                      'Start Shopping',
                      style: textTheme.labelLarge?.copyWith( // Prominent button text
                        color: AppColors.white, // White text for contrast on purple button
                        fontWeight: FontWeight.w600, // Semi-bold for importance
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // If cart has items, display them and the summary
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: cartController.cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8), // Increased space between cart items
                  itemBuilder: (context, index) {
                    final cartItem = cartController.cartItems[index];

                    final productId = cartItem['productId']?['_id'] ?? '';
                    final variantName = cartItem['variantName'] ?? '';

                    return CartItemCard(
                      cartItem: cartItem,
                      onIncrement: cartController.isLoading.value
                          ? null // Disable if an operation is in progress
                          : () => cartController.addToCart(
                        productId: productId,
                        variantName: variantName,
                      ),
                      onDecrement: cartController.isLoading.value
                          ? null // Disable if an operation is in progress
                          : () => cartController.removeFromCart(
                        productId: productId,
                        variantName: variantName,
                      ),
                    );
                  },
                ),
              ),
              // Separator for visual distinction between list and summary
              const Divider(height: 1, thickness: 1, color: AppColors.neutralBackground),
              _buildCartSummary(), // Summary section
            ],
          );
        }),
      ),
      // Overlay for loading state
      floatingActionButton: Obx(() {
        return cartController.isLoading.value
            ? Container(
          // Fills the entire screen with a translucent overlay
          color: AppColors.textDark.withOpacity(0.25), // Dark overlay for loading
          width: Get.width,
          height: Get.height,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPurple), // Loading indicator in brand color
          ),
        )
            : const SizedBox.shrink(); // Hide when not loading
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Widget to build the cart summary and checkout button
  Widget _buildCartSummary() {
    final TextTheme textTheme = Theme.of(Get.context!).textTheme; // Ensure context is available

    return Obx(() {
      final total = cartController.totalCartValue;
      final totalItems = cartController.totalCartItemsCount;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white, // White background for the summary card
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.08), // Subtle shadow for elevation
              offset: const Offset(0, -4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Takes minimum vertical space
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($totalItems ${totalItems == 1 ? 'item' : 'items'}):',
                  style: textTheme.bodyLarge?.copyWith( // Clear label for subtotal
                    color: AppColors.textLight, // Lighter text for the label
                    fontWeight: FontWeight.w500, // Medium weight
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}', // Formatted total amount
                  style: textTheme.titleLarge?.copyWith( // Prominent total amount
                    color: AppColors.primaryPurple, // Brand color for the total
                    fontWeight: FontWeight.bold, // Bold total
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, // Button stretches to full width
              height: 54, // Fixed height for button
              child: ElevatedButton(
                onPressed: cartController.isLoading.value || totalItems == 0 // Disable if loading or cart is empty
                    ? null
                    : () {
                  Get.to(() => CheckoutScreen());
                  print("Cart Products for Checkout: ${cartController.cartItems.length}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple, // Brand color for checkout button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // More rounded corners for the main action
                  ),
                  elevation: 5, // Clear elevation
                  disabledBackgroundColor: AppColors.lightPurple.withOpacity(0.5), // Lighter disabled color
                ),
                child: Text(
                  "Proceed to Checkout",
                  style: textTheme.labelLarge?.copyWith( // Prominent button text
                    color: AppColors.white, // White text on button
                    fontWeight: FontWeight.w700, // Extra bold for action
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}