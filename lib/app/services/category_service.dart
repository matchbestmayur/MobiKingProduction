import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/category_model.dart';
import '../data/sub_category_model.dart';
import 'package:dio/dio.dart' as dio;


class CategoryService {
  static const String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1';


  static Future<Map<String, dynamic>> getCategoryDetails(String slug) async {
    final response = await http.get(Uri.parse('$baseUrl/categories/details/$slug'));

    if (response.statusCode == 200) {
      final raw = json.decode(response.body);
      final data = raw['data'];

      if (data == null) {
        throw Exception("Category data is null");
      }

      final category = CategoryModel.fromJson(data); // `data` itself is the category

      final subCategories = (data['subCategories'] as List?)
          ?.map((e) => SubCategory.fromJson(e))
          .toList() ?? [];

      return {
        'category': category,
        'subCategories': subCategories,
      };
    } else {
      throw Exception('Failed to load category details');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('$baseUrl/categories');
    final response = await http.get(url);

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body);
      print('Decoded JSON: $decoded');

      final List<dynamic> jsonList = decoded['data'];
      print('Data list length: ${jsonList.length}');
      print('First item raw JSON: ${jsonList.isNotEmpty ? jsonList[0] : 'Empty list'}');

      final categories = jsonList.map((json) => CategoryModel.fromJson(json)).toList();

      print('Parsed categories count: ${categories.length}');
      if (categories.isNotEmpty) {
        print('First category name: ${categories[0].name}');
      }

      return categories;
    } else {
      throw Exception('Failed to load categories');
    }
  }



}
