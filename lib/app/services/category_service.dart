import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/category_model.dart';
import '../data/sub_category_model.dart';
import 'package:dio/dio.dart' as dio;

class CategoryService {
  static const String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1';

  static Future<Map<String, dynamic>> getCategoryDetails(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/details/$slug'));

      if (response.statusCode == 200) {
        final raw = json.decode(response.body);
        final data = raw['data'];

        if (data == null) {
          print('CategoryService: Category data is null for slug: $slug');
          return {
            'category': null,
            'subCategories': <SubCategory>[],
          };
        }

        final category = CategoryModel.fromJson(data);
        final subCategories = (data['subCategories'] as List?)
            ?.map((e) => SubCategory.fromJson(e))
            .toList() ?? <SubCategory>[];

        return {
          'category': category,
          'subCategories': subCategories,
        };
      } else {
        print('CategoryService: Failed to load category details for slug: $slug. Status: ${response.statusCode}');
        return {
          'category': null,
          'subCategories': <SubCategory>[],
        };
      }
    } catch (e) {
      print('CategoryService: Exception in getCategoryDetails: $e');
      return {
        'category': null,
        'subCategories': <SubCategory>[],
      };
    }
  }

  Future<List<CategoryModel>> getCategories() async {
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
        return categories;

      } else {
        print('CategoryService: HTTP error ${response.statusCode}: ${response.reasonPhrase}');
        return <CategoryModel>[];
      }
    } catch (e) {
      print('CategoryService: Exception in getCategories: $e');
      return <CategoryModel>[];
    }
  }
}
