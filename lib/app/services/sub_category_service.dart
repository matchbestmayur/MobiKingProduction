import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/sub_category_model.dart';

class SubCategoryService {
  final String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/categories/';

  Future<List<SubCategory>> fetchSubCategories() async {
    final url = Uri.parse('${baseUrl}subCategories');

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load subcategories: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);

    // Extract list from either raw list or from 'data' field
    final List<dynamic> list = (decoded is List) ? decoded : (decoded['data'] ?? []);
    if (list.isEmpty) return [];

    return list.map((e) {
      if (e is Map<String, dynamic>) {
        return SubCategory.fromJson(e);
      }
      throw FormatException('Invalid element type: ${e.runtimeType}');
    }).toList();
  }

  Future<SubCategory> createSubCategory(SubCategory model) async {
    final url = Uri.parse('${baseUrl}subCategories');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(model.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create subcategory: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);

    if (decoded is Map<String, dynamic> && decoded['data'] != null) {
      return SubCategory.fromJson(decoded['data']);
    }

    throw FormatException('Unexpected response format');
  }
}
