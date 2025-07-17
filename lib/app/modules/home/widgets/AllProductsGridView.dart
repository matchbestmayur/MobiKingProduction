import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming GetX is still used for navigation
import 'package:google_fonts/google_fonts.dart'; // For text styling
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';

import '../../../data/product_model.dart'; // Ensure this path is correct
// Assuming your AppColors are here
import '../../../themes/app_theme.dart';
import '../../Product_page/product_page.dart'; // Assuming your ProductPage exists
import 'ProductCard.dart'; // Ensure this path and widget name are correct
class AllProductsGridView extends StatefulWidget {
  final List<ProductModel> products;
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
  int _displayedProductsCount = 10;
  final int _productsPerPage = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || _displayedProductsCount >= widget.products.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _displayedProductsCount = (_displayedProductsCount + _productsPerPage)
            .clamp(0, widget.products.length);
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (widget.products.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Optional Section Title (if you want)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
      
            // 🔹 Product Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _displayedProductsCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: 0.50,
              ),
              itemBuilder: (context, idx) {
                final product = widget.products[idx];
                return GestureDetector(
                  onTap: () {
                    Get.to(ProductPage(
                      product: product,
                      heroTag: 'product_image_${product.id}_${product.name}_all_view',
                    ));
                  },
                  child: AllProductGridCard(
                    product: product,
                    heroTag:
                    'product_image_${product.id}_${product.name}_all_view',
                  ),
                );
              },
            ),
      
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child:
                  CircularProgressIndicator(color: AppColors.primaryPurple),
                ),
              )
            else if (_displayedProductsCount >= widget.products.length)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No more products to load.',
                    style:
                    textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                  ),
                ),
              ),
      
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.widgets_outlined,
                size: 80, color: AppColors.textLight.withOpacity(0.6)),
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
              style:
              textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              label: Text(
                'Go Back',
                style: textTheme.labelLarge?.copyWith(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
