import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming GetX is still used for navigation
import 'package:google_fonts/google_fonts.dart'; // For text styling

import '../../../data/product_model.dart'; // Ensure this path is correct
// Assuming your AppColors are here
import '../../../themes/app_theme.dart';
import '../../Product_page/product_page.dart'; // Assuming your ProductPage exists
import '../../home/widgets/ProductCard.dart';


class AllProductsGridView extends StatefulWidget {
  final List<ProductModel> products; // The full list of products
  final double horizontalPadding;
  final String title;

  const AllProductsGridView({
    super.key,
    required this.products,
    this.horizontalPadding = 16.0,
    this.title = "All Products",
  });

  @override
  State<AllProductsGridView> createState() => _AllProductsGridViewState();
}

class _AllProductsGridViewState extends State<AllProductsGridView> {
  final ScrollController _scrollController = ScrollController();
  int _displayedProductsCount = 10; // Initially show 10 products
  final int _productsPerPage = 10; // Number of products to load per "page"
  bool _isLoadingMore = false; // To prevent multiple simultaneous loads

  @override
  void initState() {
    super.initState();
    // Ensure we don't try to display more products than available initially
    _displayedProductsCount = widget.products.length < _productsPerPage
        ? widget.products.length
        : _productsPerPage;

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Check if the user has scrolled to the end of the list
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    // Only load more if not already loading and there are more products to show
    if (_isLoadingMore || _displayedProductsCount >= widget.products.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true; // Set loading state
    });

    // Simulate a small delay for "loading" the next batch
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _displayedProductsCount = (_displayedProductsCount + _productsPerPage)
            .clamp(0, widget.products.length); // Ensure it doesn't exceed total products
        _isLoadingMore = false; // Reset loading state
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          widget.title, // Use widget.title as it's a StatefulWidget
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 1,
        foregroundColor: AppColors.textDark,
      ),
      body: widget.products.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView( // The main scroll view for the entire content
        controller: _scrollController, // Attach the scroll controller
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Heading (if desired, otherwise AppBar handles it)
            // Padding(
            //   padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
            //   child: Text(
            //     widget.title,
            //     style: Theme.of(context).textTheme.titleLarge?.copyWith(
            //       fontWeight: FontWeight.bold,
            //       fontSize: 18,
            //     ),
            //   ),
            // ),

            // 🟦 Product Grid
            GridView.builder(
              shrinkWrap: true, // Essential for nested scrollables
              physics: const NeverScrollableScrollPhysics(), // GridView itself does not scroll
              itemCount: _displayedProductsCount, // Only show currently loaded products
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.61,
              ),
              itemBuilder: (context, idx) {
                final product = widget.products[idx];
                return GestureDetector(
                  onTap: (){
                    Get.to(ProductPage(product: product, heroTag: ''));
                  },
                  child: ProductCards(
                    product: product,
                    heroTag: 'product_image_${product.id}_${product.name}_all_view',
                  ),
                );
              },
            ),

            // Loading indicator or "No more products" message
            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
              )
            else if (_displayedProductsCount >= widget.products.length && widget.products.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No more products to load.',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                  ),
                ),
              ),
            const SizedBox(height: 20), // Add some space at the bottom
          ],
        ),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.widgets_outlined, size: 80, color: AppColors.textLight.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'No products found.',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'It seems there are no products available in this section yet.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              label: Text('Go Back', style: textTheme.labelLarge?.copyWith(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}