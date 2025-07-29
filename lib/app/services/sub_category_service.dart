import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/sub_category_model.dart';

class SubCategoryService {
  final String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/categories/';
  static const String boxName = 'subcategories';
  static const String lastFetchKey = 'last_fetch_timestamp';
  static const Duration cacheValidDuration = Duration(hours: 1);

  late Box<SubCategory> _subCategoriesBox;  // ✅ Added generic type
  late Box<String> _metadataBox;            // ✅ Added generic type

  // Initialize Hive boxes
  Future<void> init() async {  // ✅ Added return type
    try {
      _subCategoriesBox = await Hive.openBox<SubCategory>(boxName);
      _metadataBox = await Hive.openBox<String>('metadata');
      _log('Hive boxes initialized successfully');
    } catch (e) {
      _log('Error initializing Hive boxes: $e');
      rethrow;
    }
  }

  void _log(String message) {
    print('[SubCategoryService] $message');
  }

  // Check if cached data is still valid
  bool _isCacheValid() {
    final lastFetchString = _metadataBox.get(lastFetchKey);
    if (lastFetchString == null) return false;

    final lastFetch = DateTime.parse(lastFetchString);
    final now = DateTime.now();
    final isValid = now.difference(lastFetch) < cacheValidDuration;

    _log('Cache valid: $isValid (Last fetch: $lastFetch)');
    return isValid;
  }

  // Get cached subcategories
  List<SubCategory> _getCachedSubCategories() {  // ✅ Added generic type
    final cached = _subCategoriesBox.values.toList();
    _log('Retrieved ${cached.length} subcategories from cache');
    return cached;
  }

  // Save subcategories to cache
  Future<void> _cacheSubCategories(List<SubCategory> subCategories) async {  // ✅ Added generic types
    try {
      // Clear existing cache
      await _subCategoriesBox.clear();

      // Add all subcategories to cache
      for (final subCategory in subCategories) {
        await _subCategoriesBox.put(subCategory.id, subCategory);
      }

      // Update last fetch timestamp
      await _metadataBox.put(lastFetchKey, DateTime.now().toIso8601String());

      _log('Cached ${subCategories.length} subcategories');
    } catch (e) {
      _log('Error caching subcategories: $e');
    }
  }

  Future<List<SubCategory>> fetchSubCategories({bool forceRefresh = false}) async {
    await init(); // Ensure boxes are initialized

    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid()) {
      final cached = _getCachedSubCategories();
      if (cached.isNotEmpty) {
        _log('Returning ${cached.length} cached subcategories');
        return cached;
      }
    }

    // Fetch from API
    _log('Fetching fresh data from API...');
    final url = Uri.parse('${baseUrl}subCategories');
    _log('Fetching subcategories from: $url');

    try {
      final response = await http.get(url);
      _log('Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        _log('API request failed, trying to return cached data as fallback');

        // Return cached data as fallback if API fails
        final cached = _getCachedSubCategories();
        if (cached.isNotEmpty) {
          Get.snackbar(
            'Offline Mode',
            'Showing cached data. Please check your internet connection.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade600,
            colorText: Colors.white,
          );
          return cached;
        }

        throw Exception('Failed to load subcategories: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      _log('Successfully decoded JSON response');

      // Extract list from either raw list or from 'data' field
      final List<dynamic> list = (decoded is List) ? decoded : (decoded['data'] ?? []);

      if (list.isEmpty) {
        _log('No subcategories found');
        return [];
      }

      final subCategories = list.map((e) {
        if (e is Map<String, dynamic>) {
          return SubCategory.fromJson(e);
        }
        _log('Invalid element type: ${e.runtimeType}');
        throw FormatException('Invalid element type: ${e.runtimeType}');
      }).toList();

      _log('Successfully fetched ${subCategories.length} subcategories');

      // Cache the fresh data
      await _cacheSubCategories(subCategories);

      // Show success message only for forced refresh
      if (forceRefresh && subCategories.isNotEmpty) {
        Get.snackbar(
          'Success',
          'Data refreshed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      }

      return subCategories;
    } catch (e) {
      _log('Error while fetching subcategories: $e');

      // Try to return cached data as fallback
      final cached = _getCachedSubCategories();
      if (cached.isNotEmpty) {
        Get.snackbar(
          'Error',
          'Failed to fetch fresh data. Showing cached data.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
        );
        return cached;
      }

      throw Exception('Error while fetching subcategories: $e');
    }
  }

  Future<SubCategory> createSubCategory(SubCategory model) async {
    await init();

    final url = Uri.parse('${baseUrl}subCategories');
    _log('Creating subcategory at: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(model.toJson()),
      );

      _log('Create subcategory response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        _log('Failed to create subcategory: ${response.statusCode}');
        throw Exception('Failed to create subcategory: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      _log('Successfully decoded response for create subcategory');

      if (decoded is Map<String, dynamic> && decoded['data'] != null) {
        final createdSubCategory = SubCategory.fromJson(decoded['data']);
        _log('Successfully created subcategory: ${createdSubCategory.name}');

        // Add to cache immediately
        await _subCategoriesBox.put(createdSubCategory.id, createdSubCategory);
        _log('Added new subcategory to cache');

        Get.snackbar(
          'Success',
          'Subcategory created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );

        return createdSubCategory;
      }

      _log('Unexpected response format for create subcategory');
      throw FormatException('Unexpected response format');
    } catch (e) {
      _log('Error while creating subcategory: $e');
      throw Exception('Error while creating subcategory: $e');
    }
  }

  // Method to manually clear cache
  Future<void> clearCache() async {
    await init();
    await _subCategoriesBox.clear();
    await _metadataBox.delete(lastFetchKey);
    _log('Cache cleared');
  }

  // Method to get cache info - SAFE VERSION
  Map<String, dynamic> getCacheInfo() {
    try {
      // Ensure boxes are initialized
      if (!Hive.isBoxOpen(boxName) || !Hive.isBoxOpen('metadata')) {
        return {
          'cachedItemsCount': 0,
          'lastFetch': null,
          'isCacheValid': false,
        };
      }

      final count = _subCategoriesBox.length;
      final lastFetchString = _metadataBox.get(lastFetchKey);
      final lastFetch = lastFetchString != null ? DateTime.parse(lastFetchString) : null;
      final isValid = _isCacheValid();

      return {
        'cachedItemsCount': count,
        'lastFetch': lastFetch,
        'isCacheValid': isValid,
      };
    } catch (e) {
      _log('Error getting cache info: $e');
      return {
        'cachedItemsCount': 0,
        'lastFetch': null,
        'isCacheValid': false,
      };
    }
  }

  // Method to manually refresh data
  Future<List<SubCategory>> refreshData() async {
    return await fetchSubCategories(forceRefresh: true);
  }
}
