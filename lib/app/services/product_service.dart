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
        // ❌ Exception thrown when server doesn't return 200 (OK)
        throw Exception("Failed to fetch products: ${response.reasonPhrase} (Status: ${response.statusCode})");
      }
    } catch (e) {
      // ❌ Exception thrown for connection errors, parsing issues, or unexpected exceptions
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
      // ❌ Exception thrown when product creation fails due to bad request, server error, etc.
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
      // ❌ Exception thrown when product with given slug is not found
      throw Exception("Product not found");
    }
  }

  /// Search for products by query
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final Uri url = Uri.parse(
      '$baseUrl/products/all/search?q=${Uri.encodeComponent(query.trim())}',
    );

    try {
      final response = await http.get(url);
      print('GET $url response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data'];
        return data.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        // ❌ Exception thrown when search request fails or server returns error
        throw Exception("Failed to search products: ${response.reasonPhrase}");
      }
    } catch (e) {
      // ❌ Exception thrown for network issues, JSON parsing errors, or other unhandled problems
      throw Exception("Search error: $e");
    }
  }

  /// Get all products (fallback or if needed elsewhere)
  Future<List<ProductModel>> getAllProducts({
    int page = 1,
    int limit = 9,
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/products/all/paginated?page=$page&limit=$limit',
    );

    try {
      final response = await http.get(url);
      print('GET $url response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data']['products'];
        return data.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        // ❌ Exception thrown if the server returns an unexpected status code
        throw Exception("Failed to load products: ${response.reasonPhrase}");
      }
    } catch (e) {
      // ❌ Exception thrown for network, parsing, or unknown errors
      throw Exception("Error fetching products: $e");
    }
  }
}
