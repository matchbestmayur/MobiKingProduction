import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/sub_category_model.dart';

class SubCategoryService {
  final String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/categories/';

  void _log(String message) {
    print('[SubCategoryService] $message');
  }

  Future<List<SubCategory>> fetchSubCategories() async {
    final url = Uri.parse('${baseUrl}subCategories');
    _log('Fetching subcategories from: $url');

    try {
      final response = await http.get(url);
      _log('Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        _log('Failed to load subcategories: ${response.statusCode}');
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

      // Show success message to user only if subcategories are found
      if (subCategories.isNotEmpty) {
      /*  Get.snackbar('Success', '${subCategories.length} subcategories loaded successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white);*/
      }

      return subCategories;
    } catch (e) {
      _log('Error while fetching subcategories: $e');
      throw Exception('Error while fetching subcategories: $e');
    }
  }

  Future<SubCategory> createSubCategory(SubCategory model) async {
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

        // Show success message to user
        /*Get.snackbar('Success', 'Subcategory created successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white);*/

        return createdSubCategory;
      }

      _log('Unexpected response format for create subcategory');
      throw FormatException('Unexpected response format');
    } catch (e) {
      _log('Error while creating subcategory: $e');
      throw Exception('Error while creating subcategory: $e');
    }
  }
}
