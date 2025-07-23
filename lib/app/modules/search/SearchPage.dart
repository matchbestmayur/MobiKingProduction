import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Keep if used elsewhere or remove
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart'; // Keep if used elsewhere or remove


import '../../controllers/product_controller.dart';
import '../../services/product_service.dart'; // Keep if used elsewhere or remove
import '../../themes/app_theme.dart';
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

  final RxBool _showClearButton = false.obs;

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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Get.back(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: AppColors.lightPurple.withOpacity(0.2),
                          width: 1.0),
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
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textLight, size: 24),
                        suffixIcon: Obx(
                              () => _showClearButton.value
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textLight, size: 24),
                            onPressed: () {
                              _searchPageController.clear();
                              _onSearchInputChanged('');
                            },
                          )
                              : IconButton(
                            icon: const Icon(Icons.mic_none_rounded,
                                color: AppColors.textLight, size: 24),
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
            // ⭐ OPTIMIZED: Separate Obx widgets for different states
            Obx(() {
              // Priority 1: Validation message
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
              // Priority 2: Loading state
              else if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // Priority 3: No results found after a search query
              else if (controller.searchResults.isEmpty && _searchPageController.text.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 72,
                          color: AppColors.textLight.withOpacity(0.6),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nothing matched your search',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We couldn’t find any results for:\n"${_searchPageController.text}"',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different keyword or check for typos.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Priority 4: Initial state when search bar is empty
              else if (controller.searchResults.isEmpty && _searchPageController.text.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Start typing to search for products.',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                    ),
                  ),
                );
              }
              // Priority 5: Display search results
              else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.searchResults.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.45,
                    ),
                    itemBuilder: (context, index) {
                      final product = controller.searchResults[index];
                      return SearchProductCard(
                        product: product,
                        heroTag: 'search-product-image-${product.id}',
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