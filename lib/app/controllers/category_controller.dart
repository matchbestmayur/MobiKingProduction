import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/category_model.dart';
import '../services/category_service.dart';

class CategoryController extends GetxController {
  final CategoryService _service = CategoryService();

  // Observable variables with proper generic types
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoad = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  /// Fetch categories with Hive caching support
  Future<void> fetchCategories({bool forceRefresh = false}) async {
    try {
      if (categories.isEmpty) {
        isLoading.value = true;
        isInitialLoad.value = true;
      }

      print('[CategoryController] Fetching categories...');
      final result = await _service.getCategories(forceRefresh: forceRefresh);
      categories.assignAll(result);

      print('[CategoryController] Fetched categories count: ${result.length}');

      // Show success message only for forced refresh
      if (forceRefresh && result.isNotEmpty) {
        Get.snackbar(
          'Success',
          'Categories refreshed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      print('[CategoryController] Error in fetchCategories: $e');
      Get.snackbar(
        'Error',
        'Failed to load categories: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isInitialLoad.value = false;
    }
  }

  /// Fetch category details with caching
  Future<void> fetchCategoryDetails(String slug, {bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      print('[CategoryController] Fetching category details for slug: $slug');

      final response = await _service.getCategoryDetails(slug, forceRefresh: forceRefresh);
      selectedCategory.value = response['category'] as CategoryModel?;

      print('[CategoryController] Category details fetched for: ${selectedCategory.value?.name}');

    } catch (e) {
      print('[CategoryController] Error in fetchCategoryDetails: $e');
      Get.snackbar('Error', 'Failed to load category details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Force refresh categories from API
  Future<void> refreshCategories() async {
    await fetchCategories(forceRefresh: true);
  }

  /// Clear categories cache
  Future<void> clearCache() async {
    try {
      await _service.clearAllCache();
      Get.snackbar(
        'Success',
        'Cache cleared successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      print('[CategoryController] Error clearing cache: $e');
    }
  }

  /// Get cache information - SAFE VERSION
  Map<String, dynamic> getCacheInfo() {
    try {
      final cacheInfo = _service.getCacheInfo();
      return {
        'cachedCategoriesCount': cacheInfo['cachedCategoriesCount'] ?? 0,
        'cachedDetailsCount': cacheInfo['cachedDetailsCount'] ?? 0,
        'lastCategoriesFetch': cacheInfo['lastCategoriesFetch'],
        'isCategoriesCacheValid': cacheInfo['isCategoriesCacheValid'] ?? false,
      };
    } catch (e) {
      print('[CategoryController] Error getting cache info: $e');
      return {
        'cachedCategoriesCount': 0,
        'cachedDetailsCount': 0,
        'lastCategoriesFetch': null,
        'isCategoriesCacheValid': false,
      };
    }
  }
}
