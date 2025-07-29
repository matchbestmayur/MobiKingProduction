import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/category_model.dart';
import '../data/sub_category_model.dart';
import 'package:dio/dio.dart' as dio;

class CategoryService {
  static const String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1';

  // Hive configuration
  static const String categoriesBoxName = 'categories';
  static const String categoryDetailsBoxName = 'category_details';
  static const String metadataBoxName = 'metadata';
  static const String lastFetchCategoriesKey = 'last_fetch_categories_timestamp';
  static const String lastFetchDetailsPrefix = 'last_fetch_details_';
  static const Duration cacheValidDuration = Duration(hours: 1);

  late Box<CategoryModel> _categoriesBox;    // ✅ Added generic type
  late Box<Map> _categoryDetailsBox;         // ✅ Added generic type
  late Box<String> _metadataBox;             // ✅ Added generic type

  // Initialize Hive boxes
  Future<void> init() async {  // ✅ Added return type
    try {
      _categoriesBox = await Hive.openBox<CategoryModel>(categoriesBoxName);
      _categoryDetailsBox = await Hive.openBox<Map>(categoryDetailsBoxName);
      _metadataBox = await Hive.openBox<String>(metadataBoxName);
      print('[CategoryService] Hive boxes initialized successfully');
    } catch (e) {
      print('[CategoryService] Error initializing Hive boxes: $e');
      rethrow;
    }
  }

  // Check if cached data is still valid
  bool _isCacheValid(String key) {
    final lastFetchString = _metadataBox.get(key);
    if (lastFetchString == null) return false;

    final lastFetch = DateTime.parse(lastFetchString);
    final now = DateTime.now();
    final isValid = now.difference(lastFetch) < cacheValidDuration;

    print('[CategoryService] Cache valid for $key: $isValid (Last fetch: $lastFetch)');
    return isValid;
  }

  // Get cached categories
  List<CategoryModel> _getCachedCategories() {  // ✅ Added generic type
    final cached = _categoriesBox.values.toList();
    print('[CategoryService] Retrieved ${cached.length} categories from cache');
    return cached;
  }

  // Save categories to cache
  Future<void> _cacheCategories(List<CategoryModel> categories) async {  // ✅ Added generic types
    try {
      // Clear existing cache
      await _categoriesBox.clear();

      // Add all categories to cache
      for (final category in categories) {
        await _categoriesBox.put(category.id, category);
      }

      // Update last fetch timestamp
      await _metadataBox.put(lastFetchCategoriesKey, DateTime.now().toIso8601String());

      print('[CategoryService] Cached ${categories.length} categories');
    } catch (e) {
      print('[CategoryService] Error caching categories: $e');
    }
  }

  // Get cached category details
  Map<String, dynamic>? _getCachedCategoryDetails(String slug) {
    final cached = _categoryDetailsBox.get(slug);
    if (cached != null) {
      print('[CategoryService] Retrieved cached category details for slug: $slug');
      // Convert the cached Map back to the expected format
      return {
        'category': cached['category'] != null
            ? CategoryModel.fromJson(Map<String, dynamic>.from(cached['category']))
            : null,
        'subCategories': (cached['subCategories'] as List?)
            ?.map((e) => SubCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList() ?? <SubCategory>[],
      };
    }
    return null;
  }

  // Save category details to cache
  Future<void> _cacheCategoryDetails(String slug, Map<String, dynamic> details) async {
    try {
      // Convert to a serializable format
      final cacheData = {
        'category': details['category']?.toJson(),
        'subCategories': (details['subCategories'] as List<SubCategory>?)
            ?.map((e) => e.toJson())
            .toList() ?? [],
      };

      await _categoryDetailsBox.put(slug, cacheData);

      // Update last fetch timestamp for this specific slug
      await _metadataBox.put('$lastFetchDetailsPrefix$slug', DateTime.now().toIso8601String());

      print('[CategoryService] Cached category details for slug: $slug');
    } catch (e) {
      print('[CategoryService] Error caching category details for $slug: $e');
    }
  }

  Future<Map<String, dynamic>> getCategoryDetails(String slug, {bool forceRefresh = false}) async {
    await init(); // Ensure boxes are initialized

    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid('$lastFetchDetailsPrefix$slug')) {
      final cached = _getCachedCategoryDetails(slug);
      if (cached != null) {
        print('[CategoryService] Returning cached category details for slug: $slug');
        return cached;
      }
    }

    // Fetch from API
    print('[CategoryService] Fetching fresh category details from API for slug: $slug');

    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/details/$slug'));

      if (response.statusCode == 200) {
        final raw = json.decode(response.body);
        final data = raw['data'];

        if (data == null) {
          print('CategoryService: Category data is null for slug: $slug');
          final emptyResult = {
            'category': null,
            'subCategories': <SubCategory>[],
          };
          // Cache empty result to avoid repeated API calls
          await _cacheCategoryDetails(slug, emptyResult);
          return emptyResult;
        }

        final category = CategoryModel.fromJson(data);
        final subCategories = (data['subCategories'] as List?)
            ?.map((e) => SubCategory.fromJson(e))
            .toList() ?? <SubCategory>[];

        final result = {
          'category': category,
          'subCategories': subCategories,
        };

        // Cache the fresh data
        await _cacheCategoryDetails(slug, result);

        print('CategoryService: Successfully fetched category details for slug: $slug');

        // Show success message only for forced refresh
        if (forceRefresh) {
          Get.snackbar(
            'Success',
            'Category details refreshed successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
          );
        }

        return result;
      } else {
        print('CategoryService: Failed to load category details for slug: $slug. Status: ${response.statusCode}');

        // Try to return cached data as fallback
        final cached = _getCachedCategoryDetails(slug);
        if (cached != null) {
          Get.snackbar(
            'Error',
            'Failed to fetch fresh data. Showing cached data.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade600,
            colorText: Colors.white,
          );
          return cached;
        }

        return {
          'category': null,
          'subCategories': <SubCategory>[],
        };
      }
    } catch (e) {
      print('CategoryService: Exception in getCategoryDetails: $e');

      // Try to return cached data as fallback
      final cached = _getCachedCategoryDetails(slug);
      if (cached != null) {
        Get.snackbar(
          'Error',
          'Failed to fetch category details. Showing cached data.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
        );
        return cached;
      }

      return {
        'category': null,
        'subCategories': <SubCategory>[],
      };
    }
  }

  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    await init(); // Ensure boxes are initialized

    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid(lastFetchCategoriesKey)) {
      final cached = _getCachedCategories();
      if (cached.isNotEmpty) {
        print('[CategoryService] Returning ${cached.length} cached categories');
        return cached;
      }
    }

    // Fetch from API
    print('[CategoryService] Fetching fresh categories from API...');

    try {
      final url = Uri.parse('$baseUrl/categories');
      final response = await http.get(url);

      print('CategoryService: Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        print('CategoryService: Successfully decoded JSON response');

        final dynamic dataField = decoded['data'];

        if (dataField == null) {
          print('CategoryService: Data field is null in response');
          return <CategoryModel>[];
        }

        if (dataField is! List) {
          print('CategoryService: Data field is not a list: ${dataField.runtimeType}');
          return <CategoryModel>[];
        }

        final List<dynamic> jsonList = dataField;
        print('CategoryService: Data list length: ${jsonList.length}');

        if (jsonList.isEmpty) {
          print('CategoryService: Empty categories list received from API');
          return <CategoryModel>[];
        }

        final List<CategoryModel> categories = [];

        for (int i = 0; i < jsonList.length; i++) {
          try {
            final categoryJson = jsonList[i];
            if (categoryJson != null && categoryJson is Map<String, dynamic>) {
              final category = CategoryModel.fromJson(categoryJson);
              categories.add(category);
            } else {
              print('CategoryService: Invalid category data at index $i: $categoryJson');
            }
          } catch (e) {
            print('CategoryService: Error parsing category at index $i: $e');
            // Continue with other categories instead of failing completely
          }
        }

        print('CategoryService: Successfully parsed ${categories.length} categories');

        // Cache the fresh data
        await _cacheCategories(categories);

        // Show success message only for forced refresh
        if (forceRefresh && categories.isNotEmpty) {
          Get.snackbar(
            'Success',
            'Categories refreshed successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
          );
        }

        return categories;

      } else {
        print('CategoryService: HTTP error ${response.statusCode}: ${response.reasonPhrase}');

        // Try to return cached data as fallback
        final cached = _getCachedCategories();
        if (cached.isNotEmpty) {
          Get.snackbar(
            'Error',
            'Failed to fetch fresh data. Showing cached categories.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade600,
            colorText: Colors.white,
          );
          return cached;
        }

        return <CategoryModel>[];
      }
    } catch (e) {
      print('CategoryService: Exception in getCategories: $e');

      // Try to return cached data as fallback
      final cached = _getCachedCategories();
      if (cached.isNotEmpty) {
        Get.snackbar(
          'Error',
          'Failed to fetch categories. Showing cached data.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
        );
        return cached;
      }

      return <CategoryModel>[];
    }
  }

  // Method to manually clear categories cache
  Future<void> clearCategoriesCache() async {
    await init();
    await _categoriesBox.clear();
    await _metadataBox.delete(lastFetchCategoriesKey);
    print('[CategoryService] Categories cache cleared');
  }

  // Method to manually clear category details cache
  Future<void> clearCategoryDetailsCache([String? slug]) async {
    await init();
    if (slug != null) {
      // Clear specific category details
      await _categoryDetailsBox.delete(slug);
      await _metadataBox.delete('$lastFetchDetailsPrefix$slug');
      print('[CategoryService] Category details cache cleared for slug: $slug');
    } else {
      // Clear all category details
      await _categoryDetailsBox.clear();
      // Clear all details timestamps
      final keys = _metadataBox.keys.where((key) => key.startsWith(lastFetchDetailsPrefix)).toList();
      for (final key in keys) {
        await _metadataBox.delete(key);
      }
      print('[CategoryService] All category details cache cleared');
    }
  }

  // Method to clear all cache
  Future<void> clearAllCache() async {
    await clearCategoriesCache();
    await clearCategoryDetailsCache();
    print('[CategoryService] All cache cleared');
  }

  // Method to get cache info - SAFE VERSION
  Map<String, dynamic> getCacheInfo() {
    try {
      // Ensure boxes are initialized
      if (!Hive.isBoxOpen(categoriesBoxName) || !Hive.isBoxOpen(metadataBoxName)) {
        return {
          'cachedCategoriesCount': 0,
          'cachedDetailsCount': 0,
          'lastCategoriesFetch': null,
          'isCategoriesCacheValid': false,
        };
      }

      final categoriesCount = _categoriesBox.length;
      final detailsCount = _categoryDetailsBox.length;
      final lastFetchString = _metadataBox.get(lastFetchCategoriesKey);
      final lastFetch = lastFetchString != null ? DateTime.parse(lastFetchString) : null;
      final isCategoriesCacheValid = _isCacheValid(lastFetchCategoriesKey);

      return {
        'cachedCategoriesCount': categoriesCount,
        'cachedDetailsCount': detailsCount,
        'lastCategoriesFetch': lastFetch,
        'isCategoriesCacheValid': isCategoriesCacheValid,
      };
    } catch (e) {
      print('[CategoryService] Error getting cache info: $e');
      return {
        'cachedCategoriesCount': 0,
        'cachedDetailsCount': 0,
        'lastCategoriesFetch': null,
        'isCategoriesCacheValid': false,
      };
    }
  }

  // Method to manually refresh categories data
  Future<List<CategoryModel>> refreshCategories() async {
    return await getCategories(forceRefresh: true);
  }

  // Method to manually refresh category details data
  Future<Map<String, dynamic>> refreshCategoryDetails(String slug) async {
    return await getCategoryDetails(slug, forceRefresh: true);
  }
}
