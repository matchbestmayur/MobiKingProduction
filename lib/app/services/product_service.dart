import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/product_model.dart';

class ProductService {
  static const String baseUrl = "https://mobiking-e-commerce-backend-prod.vercel.app/api/v1";

  /// Fetch products with given limit (page is fixed to 1 for your new design)
  Future<List<ProductModel>> getProductsPaginated({required int limit}) async {
    final url = Uri.parse('$baseUrl/products?page=1&limit=$limit');
    print('GET /products?page=1&limit=$limit'); // For debugging

    try {
      final response = await http.get(url);
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data'];
        return data.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to fetch products: ${response.reasonPhrase} (Status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error while fetching products: $e");
    }
  }

  /// Create a new product
  Future<ProductModel> createProduct(ProductModel product) async {
    final url = Uri.parse('$baseUrl/products/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    print('POST /products/create response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ProductModel.fromJson(jsonData['data']);
    } else {
      throw Exception("Failed to create product: ${response.reasonPhrase}");
    }
  }

  /// Fetch single product by slug
  Future<ProductModel> fetchProductBySlug(String slug) async {
    final url = Uri.parse('$baseUrl/products/details/$slug');
    final response = await http.get(url);
    print('GET /products/details/$slug response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ProductModel.fromJson(jsonData['data']);
    } else {
      throw Exception("Product not found");
    }
  }

  Future<List<ProductModel>> searchProducts(
      String query, {
        int page = 1,
        int limit = 20,
        String startDate = '2025-01-01',
        String endDate = '2025-12-31',
      }) async {
    if (query.trim().isEmpty) return [];

    final Uri url = Uri.parse(
      '$baseUrl/products/all/paginated?page=$page&limit=$limit'
          '&startDate=$startDate&endDate=$endDate&searchQuery=${Uri.encodeComponent(query.trim())}',
    );

    try {
      final response = await http.get(url);
      print('GET $url response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data']['products']; // ✅ FIXED HERE
        return data.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to search products: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Search error: $e");
    }
  }



  /// Get all products (fallback or if needed elsewhere)
  Future<List<ProductModel>> getAllProducts({
    int page = 1,
    int limit = 20,
    String startDate = '2025-01-01',
    String endDate = '2025-12-31',
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/products/all/paginated?page=$page&limit=$limit'
          '&startDate=$startDate&endDate=$endDate',
    );

    try {
      final response = await http.get(url);
      print('GET $url response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data']['products']; // ✅ FIXED HERE
        return data.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load products: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }


}
