import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';
import 'dart:async';

import '../../controllers/product_controller.dart';
import '../../services/product_service.dart';
import '../../themes/app_theme.dart';
import 'Serach_product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchPageController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final RxList<String> _recentSearches = <String>[].obs;
  final RxBool _showClearButton = false.obs;
  final ProductController controller = Get.find<ProductController>();
  final RxString _validationMessage = ''.obs;

  // ✅ Pagination variables
  final RxList<dynamic> _displayedProducts = <dynamic>[].obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasMoreProducts = true.obs;
  static const int _productsPerPage = 20;
  int _currentPage = 0;

  // ✅ Optimized debounce
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // ✅ Performance optimization flags
  bool _isSearching = false;
  String _lastSearchQuery = '';

  // ✅ Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ✅ Keyboard optimization flags
  bool _keyboardVisible = false;
  bool _isKeyboardAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSearch();

    // ✅ Add observer for keyboard detection
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  void _initializeSearch() {
    _searchPageController.addListener(_onSearchPageControllerChanged);
    _scrollController.addListener(_onScrollChanged);

    // ✅ No auto-focus to prevent keyboard lag - user taps to focus
  }

  // ✅ CORRECTED: Proper keyboard detection
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0.0;

    if (newKeyboardVisible != _keyboardVisible) {
      setState(() {
        _keyboardVisible = newKeyboardVisible;
        _isKeyboardAnimating = true;
      });

      // Reset animation flag after keyboard animation completes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isKeyboardAnimating = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);

    _searchPageController.removeListener(_onSearchPageControllerChanged);
    _scrollController.removeListener(_onScrollChanged);
    _searchPageController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchPageControllerChanged() {
    final hasText = _searchPageController.text.isNotEmpty;
    if (_showClearButton.value != hasText) {
      _showClearButton.value = hasText;
    }
    _onSearchInputChanged(_searchPageController.text);
  }

  void _onScrollChanged() {
    // Auto-load more when near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _onSearchInputChanged(String query) {
    final trimmedQuery = query.trim();

    // ✅ Prevent unnecessary processing
    if (_isSearching || trimmedQuery == _lastSearchQuery) return;

    _debounceTimer?.cancel();

    if (trimmedQuery.isEmpty) {
      _resetSearch();
      return;
    }

    if (trimmedQuery.length < 2) {
      _displayedProducts.clear();
      _validationMessage.value = 'Please enter at least 2 characters to search.';
      return;
    }

    _validationMessage.value = '';

    // ✅ Optimized debouncing
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted && !_isSearching) {
        _performSearch(trimmedQuery);
      }
    });
  }

  void _resetSearch() {
    _displayedProducts.clear();
    _currentPage = 0;
    _hasMoreProducts.value = true;
    _validationMessage.value = 'Start typing to search for products.';
    _lastSearchQuery = '';
  }

  Future<void> _performSearch(String query) async {
    if (_isSearching) return;

    _isSearching = true;
    _lastSearchQuery = query;
    _currentPage = 0;
    _hasMoreProducts.value = true;

    try {
      await controller.searchProducts(query);
      _updateDisplayedProducts();
    } finally {
      _isSearching = false;
    }
  }

  void _updateDisplayedProducts() {
    final allResults = controller.searchResults;
    final startIndex = _currentPage * _productsPerPage;
    final endIndex = (startIndex + _productsPerPage).clamp(0, allResults.length);

    if (_currentPage == 0) {
      _displayedProducts.clear();
    }

    if (startIndex < allResults.length) {
      _displayedProducts.addAll(allResults.getRange(startIndex, endIndex));
      _hasMoreProducts.value = endIndex < allResults.length;
    } else {
      _hasMoreProducts.value = false;
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore.value || !_hasMoreProducts.value || _isSearching) return;

    _isLoadingMore.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _currentPage++;
      _updateDisplayedProducts();
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void _addRecentSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isNotEmpty && cleanQuery.length >= 2) {
      _recentSearches.remove(cleanQuery);
      _recentSearches.insert(0, cleanQuery);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    }
  }

  // ✅ OPTIMIZED: Handle search field tap with haptic feedback
  void _handleSearchFieldTap() {
    HapticFeedback.lightImpact();
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      // ✅ CRITICAL: Dynamic resize behavior
      resizeToAvoidBottomInset: true,
      body: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // ✅ Fixed header with keyboard awareness
              _buildOptimizedHeader(textTheme, context),
              // ✅ Dynamic body that adapts to keyboard
              Expanded(
                child: _buildKeyboardAwareBody(textTheme, context, keyboardHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ OPTIMIZED header with better keyboard handling
  Widget _buildOptimizedHeader(TextTheme textTheme, BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Container(
      height: statusBarHeight + 80,
      width: double.infinity,
      color: AppColors.white,
      child: Column(
        children: [
          SizedBox(height: statusBarHeight),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildOptimizedSearchField(textTheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ HIGHLY OPTIMIZED search field for smooth keyboard interaction
  Widget _buildOptimizedSearchField(TextTheme textTheme) {
    return GestureDetector(
      onTap: _handleSearchFieldTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _searchFocusNode.hasFocus
                ? AppColors.primaryPurple.withOpacity(0.9)
                : AppColors.lightPurple.withOpacity(0.2),
            width: _searchFocusNode.hasFocus ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchPageController,
          focusNode: _searchFocusNode,
          onSubmitted: (query) {
            _addRecentSearch(query);
            HapticFeedback.selectionClick();
          },
          onChanged: (value) {
            // ✅ Light haptic feedback on typing
            if (value.length == 1) {
              HapticFeedback.selectionClick();
            }
          },
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primaryPurple,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          // ✅ CRITICAL: Optimize keyboard type and input formatting
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.none,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\n')), // Prevent line breaks
          ],
          decoration: InputDecoration(
            hintText: 'Search for products...',
            hintStyle: textTheme.bodySmall?.copyWith(
              color: AppColors.textLight.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search_rounded,
                color: _searchFocusNode.hasFocus
                    ? AppColors.primaryPurple
                    : AppColors.textLight,
                size: 20,
              ),
            ),
            suffixIcon: Obx(() => _showClearButton.value
                ? SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: AppColors.textLight, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _searchPageController.clear();
                  _resetSearch();
                },
              ),
            )
                : const SizedBox(width: 40, height: 40)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isDense: true,
            isCollapsed: false,
          ),
        ),
      ),
    );
  }

  // ✅ OPTIMIZED body with keyboard-aware scrolling
  Widget _buildKeyboardAwareBody(TextTheme textTheme, BuildContext context, double keyboardHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: CustomScrollView(
        controller: _scrollController,
        // ✅ Optimized physics for smooth scrolling even with keyboard
        physics: _isKeyboardAnimating
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ✅ Keyboard-aware spacing
          if (keyboardHeight > 0)
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Recent Searches
          _buildOptimizedRecentSearches(textTheme),

          // Search Results Header
          _buildOptimizedSearchResultsHeader(textTheme),

          // Search Results Content
          _buildOptimizedSearchResults(textTheme),

          // Load More Button
          _buildOptimizedLoadMoreButton(textTheme),

          // Dynamic bottom padding based on keyboard
          SliverToBoxAdapter(
            child: SizedBox(
              height: keyboardHeight > 0 ? 20 : 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedRecentSearches(TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (_recentSearches.isEmpty) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(
            minHeight: 0,
            maxHeight: 200,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _recentSearches.clear();
                      },
                      child: Text(
                        'Clear All',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _recentSearches
                        .map((search) => _buildOptimizedRecentSearchChip(search, textTheme))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOptimizedRecentSearchChip(String search, TextTheme textTheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _searchPageController.text = search;
          _performSearch(search);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(
            maxWidth: 200,
            minHeight: 32,
            maxHeight: 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neutralBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightPurple.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 16, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  search,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 20,
                height: 20,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _recentSearches.remove(search);
                    if (_searchPageController.text == search) {
                      _searchPageController.clear();
                      _resetSearch();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Icon(Icons.close, size: 14, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedSearchResultsHeader(TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              'Search Results',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              if (_displayedProducts.isNotEmpty) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    maxWidth: 60,
                    minHeight: 20,
                    maxHeight: 24,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_displayedProducts.length}${_hasMoreProducts.value ? '+' : ''}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedSearchResults(TextTheme textTheme) {
    return Obx(() {
      // Validation message
      if (_validationMessage.isNotEmpty) {
        return _buildOptimizedMessageState(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.primaryPurple,
          title: _validationMessage.value,
          subtitle: null,
        );
      }

      // Loading state
      if (controller.isLoading.value && _displayedProducts.isEmpty) {
        return _buildOptimizedLoadingState(textTheme);
      }

      // No results
      if (_displayedProducts.isEmpty &&
          _searchPageController.text.isNotEmpty &&
          !controller.isLoading.value) {
        return _buildOptimizedMessageState(
          icon: Icons.search_off_rounded,
          iconColor: AppColors.textLight,
          title: 'No results found',
          subtitle: 'We couldn\'t find any products matching "${_searchPageController.text}"',
        );
      }

      // Empty state
      if (_displayedProducts.isEmpty && _searchPageController.text.isEmpty) {
        return _buildOptimizedMessageState(
          icon: Icons.search_rounded,
          iconColor: AppColors.textLight,
          title: 'Start typing to search for products',
          subtitle: null,
        );
      }

      // Results grid
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final product = _displayedProducts[index];
              return RepaintBoundary(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 120,
                    maxHeight: 300,
                  ),
                  child: SearchProductCard(
                    key: ValueKey('search-${product.id}-$index'),
                    product: product,
                    heroTag: 'search-product-image-${product.id}-$index',
                  ),
                ),
              );
            },
            childCount: _displayedProducts.length,
            addRepaintBoundaries: false,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.45,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            mainAxisExtent: 280,
          ),
        ),
      );
    });
  }

  Widget _buildOptimizedLoadMoreButton(TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (!_hasMoreProducts.value || _displayedProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 80,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: _isLoadingMore.value
                ? Container(
              constraints: const BoxConstraints(
                maxWidth: 200,
                maxHeight: 48,
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Loading more...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
                : ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 200,
                maxHeight: 48,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _loadMoreProducts();
                },
                icon: Icon(Icons.expand_more, color: AppColors.white),
                label: Text(
                  'Load More',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOptimizedMessageState({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: const BoxConstraints(
          minHeight: 200,
          maxHeight: 400,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: iconColor),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedLoadingState(TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Searching products...',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
