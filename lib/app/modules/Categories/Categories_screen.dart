import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryProductsGridScreen.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryProductsScreen.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductsGridView.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryTile.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

import '../../controllers/category_controller.dart';
import '../../controllers/sub_category_controller.dart';
import '../../themes/app_theme.dart';

class CategorySectionScreen extends StatefulWidget {
  const CategorySectionScreen({super.key});

  @override
  State<CategorySectionScreen> createState() => _CategorySectionScreenState();
}

class _CategorySectionScreenState extends State<CategorySectionScreen> {
  final CategoryController categoryController = Get.find();
  final SubCategoryController subCategoryController = Get.find();

  Timer? _retryTimer;
  final RxBool _hasLoadingFailed = false.obs;
  final RxInt _retryCount = 0.obs;
  final int _maxRetries = 5; // Stop auto-retry after 5 attempts

  @override
  void initState() {
    super.initState();
    _checkLoadingState();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _checkLoadingState() {
    // Check if both controllers have failed to load data
    ever(_hasLoadingFailed, (bool hasFailed) {
      if (hasFailed && _retryCount.value < _maxRetries) {
        _startAutoRetry();
      } else if (!hasFailed) {
        _stopAutoRetry();
      }
    });
  }

  void _startAutoRetry() {
    _stopAutoRetry(); // Cancel any existing timer

    _retryTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_retryCount.value >= _maxRetries) {
        _stopAutoRetry();
        return;
      }

      print('📱 CategorySectionScreen: Auto-retry attempt ${_retryCount.value + 1}/$_maxRetries');
      _retryCount.value++;

      try {
        await _refreshData();

        // Check if data loaded successfully
        if (categoryController.categories.isNotEmpty ||
            subCategoryController.subCategories.isNotEmpty) {
          _hasLoadingFailed.value = false;
          _retryCount.value = 0;
          _stopAutoRetry();
        }
      } catch (e) {
        print('📱 CategorySectionScreen: Auto-retry failed: $e');
      }
    });
  }

  void _stopAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> _refreshData() async {
    try {
      await Future.wait([
        categoryController.fetchCategories(),
        subCategoryController.loadSubCategories(),
      ]);
    } catch (e) {
      print('📱 CategorySectionScreen: Error refreshing data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text("Categories",
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        centerTitle: false,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        // ✅ Check if EITHER controller is loading
        final bool isAnyLoading = categoryController.isLoading.value ||
            subCategoryController.isLoading.value;

        if (isAnyLoading) {
          return _buildLoadingState(context);
        }

        final allCategories = categoryController.categories;
        final availableSubCategories = subCategoryController.subCategories;

        // ✅ Check for failed state
        final bool hasFailedToLoad = allCategories.isEmpty &&
            availableSubCategories.isEmpty &&
            !isAnyLoading;

        if (hasFailedToLoad) {
          // Update failed state for auto-retry
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _hasLoadingFailed.value = true;
          });

          return _buildFailedState(context);
        } else {
          // Reset failed state if data loaded successfully
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _hasLoadingFailed.value = false;
            _retryCount.value = 0;
          });
        }

        // ✅ Additional check: if categories loaded but no subcategories yet
        if (allCategories.isNotEmpty && availableSubCategories.isEmpty) {
          return _buildLoadingState(context);
        }

        final availableSubCatIds = availableSubCategories.map((e) => e.id).toSet();

        final filteredCategories = allCategories.where((cat) {
          return (cat.subCategoryIds ?? []).any(availableSubCatIds.contains);
        }).toList();

        // ✅ Only show empty state when we're sure both controllers have finished loading
        if (filteredCategories.isEmpty && !isAnyLoading) {
          return _buildEmptyState(context);
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCategories.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  final title = category.name ?? "Unnamed Category";

                  final matchingSubs = availableSubCategories
                      .where((sub) => (category.subCategoryIds ?? []).contains(sub.id))
                      .toList();

                  if (matchingSubs.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(title,
                                style: textTheme.titleLarge?.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.to(() => CategoryProductsGridScreen(
                                categoryName: title,
                                subCategories: matchingSubs,
                              )),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.success,
                                textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("See More", style: TextStyle(color: AppColors.success)),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Grid of subcategories
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: matchingSubs.length > 6 ? 6 : matchingSubs.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, i) {
                            final sub = matchingSubs[i];
                            final image = (sub.photos?.isNotEmpty ?? false)
                                ? sub.photos!.first
                                : "https://via.placeholder.com/150x150/E0E0E0/A0A0A0?text=No+Image";

                            return CategoryTile(
                              title: sub.name ?? 'Unknown',
                              imageUrl: image,
                              onTap: () {
                                Get.to(() => CategoryProductsGridScreen(
                                  categoryName: title,
                                  subCategories: matchingSubs,
                                ));
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),
              _buildBrandingSection(textTheme),
            ],
          ),
        );
      }),
    );
  }

  // Enhanced loading state
  Widget _buildLoadingState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer title
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.grey[50]!,
                child: Container(
                  width: 180,
                  height: textTheme.titleLarge?.fontSize ?? 22,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Shimmer grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.grey[50]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ✅ NEW: Failed state with auto-retry indicator
  Widget _buildFailedState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                Icons.cloud_off_outlined,
                size: 80,
                color: AppColors.textLight.withOpacity(0.6)
            ),
            const SizedBox(height: 16),
            Text('Failed to load categories',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              _retryCount.value > 0
                  ? 'Auto-retrying... (${_retryCount.value}/$_maxRetries)'
                  : 'Checking connection...',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 24),
            // ✅ Loading indicator during auto-retry
            Obx(() => _retryCount.value > 0 && _retryCount.value < _maxRetries
                ? Column(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Next retry in 3 seconds...',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 24),
              ],
            )
                : const SizedBox.shrink()
            ),
            ElevatedButton.icon(
              onPressed: () async {
                _retryCount.value = 0;
                _hasLoadingFailed.value = false;
                await _refreshData();
              },
              icon: const Icon(Icons.refresh, color: AppColors.white),
              label: Text('Retry Now', style: textTheme.labelLarge?.copyWith(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Stop auto-retry button
            Obx(() => _retryCount.value > 0
                ? TextButton(
              onPressed: () {
                _stopAutoRetry();
                _hasLoadingFailed.value = false;
                _retryCount.value = 0;
              },
              child: Text(
                'Stop Auto-Retry',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textLight),
              ),
            )
                : const SizedBox.shrink()
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: AppColors.textLight.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text('No categories available at the moment.',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Please check back later!',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // ✅ Refresh both controllers
                await _refreshData();
              },
              icon: const Icon(Icons.refresh, color: AppColors.white),
              label: Text('Retry', style: textTheme.labelLarge?.copyWith(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
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

  Widget _buildBrandingSection(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mobiking",
            style: textTheme.displayLarge?.copyWith(
              color: AppColors.textLight.withOpacity(0.5),
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text("Your Wholesale Partner",
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textLight.withOpacity(0.6),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Buy in bulk, save big. Get the best deals on mobile phones and accessories, delivered directly to your doorstep.",
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textLight.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
