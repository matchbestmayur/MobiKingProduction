import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:mobiking/app/modules/home/widgets/ProductCard.dart'; // Ensure this is still used if applicable or remove
import 'package:mobiking/app/themes/app_theme.dart';
import '../../data/product_model.dart'; // Ensure this is still used if applicable or remove
import '../../services/product_service.dart'; // Ensure this is still used if applicable or remove
import 'Serach_product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchPageController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final RxList<String> _recentSearches = <String>[].obs;
  // _allProducts and _filteredProducts are no longer strictly needed here
  // if ProductController is managing all product data and search results.
  // Keeping them for now, but consider removing if redundant.
  final RxList<ProductModel> _allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> _filteredProducts = <ProductModel>[].obs;

  final RxBool _showClearButton = false.obs;

  // ProductService and _isLoadingProducts/_productErrorMessage might be redundant
  // if ProductController is handling all data fetching and error states.
  // Review if these can be removed or managed solely by ProductController.
  final ProductService _productService = ProductService();
  final RxBool _isLoadingProducts = true.obs; // Consider removing
  final RxString _productErrorMessage = ''.obs; // Consider removing

  // ⭐ GetX Controller instance
  final ProductController controller = Get.find<ProductController>();

  // ⭐ New RxString to show validation message
  final RxString _validationMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    _searchPageController.addListener(_onSearchPageControllerChanged);
    // Removed _fetchAllProducts call from here as ProductController handles it onInit.
    // If you need to ensure products are always loaded when search page is opened,
    // ensure ProductController.fetchProducts() is called or its state persists.
  }

  @override
  void dispose() {
    _searchPageController.removeListener(_onSearchPageControllerChanged);
    _searchPageController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchPageControllerChanged() {
    _showClearButton.value = _searchPageController.text.isNotEmpty;
    _onSearchInputChanged(_searchPageController.text);
  }

  void _onSearchInputChanged(String query) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      controller.searchResults.clear();
      _validationMessage.value = 'Start typing to search for products.'; // Initial hint
      return;
    }

    // ⭐ Add frontend validation for minimum characters
    if (trimmedQuery.length < 2) {
      controller.searchResults.clear(); // Clear old results
      _validationMessage.value = 'Please enter at least 2 characters to search.';
      return;
    }

    _validationMessage.value = ''; // Clear validation message if input is valid
    controller.searchProducts(trimmedQuery);
  }


  void _addRecentSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isNotEmpty) {
      if (_recentSearches.contains(cleanQuery)) {
        _recentSearches.remove(cleanQuery);
      }
      _recentSearches.insert(0, cleanQuery);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    }
  }

  // _fetchAllProducts is likely redundant now if ProductController fetches all products
  // and search results are managed by ProductController.searchProducts.
  // Consider removing this method if ProductController handles all product data.
  Future<void> _fetchAllProducts() async {
    // This method might not be needed if controller.productList is the source of truth
    // and controller.searchProducts is the main way to get filtered data.
    // For now, keeping it as a fallback or if it has another purpose.
    _isLoadingProducts.value = true;
    _productErrorMessage.value = '';
    try {
      final products = await _productService.getAllProducts();
      _allProducts.assignAll(products);
      _filteredProducts.assignAll(products); // Still assigning to _filteredProducts, but likely unused
    } catch (e) {
      _productErrorMessage.value = 'Failed to load products: ${e.toString()}';
    } finally {
      _isLoadingProducts.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,size: 18,),
                  onPressed: () => Get.back(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.lightPurple.withOpacity(0.2), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textDark.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchPageController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchInputChanged,
                      onSubmitted: (query) {
                        _addRecentSearch(query);
                        FocusScope.of(context).unfocus();
                      },
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: AppColors.primaryPurple,
                      decoration: InputDecoration(
                        hintText: 'Search for products...',
                        hintStyle: textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 24),
                        suffixIcon: Obx(
                              () => _showClearButton.value
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textLight, size: 24),
                            onPressed: () {
                              _searchPageController.clear();
                              _onSearchInputChanged('');
                            },
                          )
                              : IconButton(
                            icon: const Icon(Icons.mic_none_rounded, color: AppColors.textLight, size: 24),
                            onPressed: () {
                              debugPrint('Microphone tapped');
                            },
                          ),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (_recentSearches.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Searches',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _recentSearches.map((search) {
                        return Chip(
                          avatar: const Icon(Icons.history, size: 18, color: AppColors.primaryPurple),
                          label: Text(search),
                          labelStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                          backgroundColor: AppColors.neutralBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          onDeleted: () {
                            _recentSearches.remove(search);
                            if (_searchPageController.text == search) {
                              _searchPageController.clear();
                              _onSearchInputChanged('');
                            }
                          },
                          deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textLight),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Search Results',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              // ⭐ Display validation message
              if (_validationMessage.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 64, color: AppColors.primaryPurple),
                        const SizedBox(height: 12),
                        Text(
                          _validationMessage.value,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Existing loading and no results logic
              else if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (controller.searchResults.isEmpty && _searchPageController.text.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        Text(
                          'No results found for "${_searchPageController.text}".',
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else if (controller.searchResults.isEmpty && _searchPageController.text.isEmpty) {
                // This block might become redundant if _validationMessage handles initial hint.
                // Keeping it for now but review if it can be merged with _validationMessage logic.
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Start typing to search for products.',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.searchResults.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final product = controller.searchResults[index];
                      return SearchProductCard(
                        product: product,
                        heroTag: 'search-product-image-${product.id ?? index}',
                      );
                    },
                  ),
                );
              }
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}