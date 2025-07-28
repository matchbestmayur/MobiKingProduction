import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/product_model.dart';

class ProductService {
  static const String baseUrl = "https://mobiking-e-commerce-backend-prod.vercel.app/api/v1";

  void _log(String message) {
    print('[ProductService] $message');
  }

  /// Fetch products with given limit (page is fixed to 1 for your new design)
  Future<List<ProductModel>> getProductsPaginated({required int limit}) async {
    final url = Uri.parse('$baseUrl/products?page=1&limit=$limit');
    _log('GET /products?page=1&limit=$limit');

    try {
      final response = await http.get(url);
      _log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data'];
        final products = data.map((e) => ProductModel.fromJson(e)).toList();

        _log('Successfully fetched ${products.length} products');

        return products;
      } else {
        _log("Failed to fetch products: ${response.reasonPhrase} (Status: ${response.statusCode})");
        throw Exception("Failed to fetch products: ${response.reasonPhrase} (Status: ${response.statusCode})");
      }
    } catch (e) {
      _log("Error while fetching products: $e");
      throw Exception("Error while fetching products: $e");
    }
  }

  /// Create a new product
  Future<ProductModel> createProduct(ProductModel product) async {
    final url = Uri.parse('$baseUrl/products/create');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );

      _log('POST /products/create response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final createdProduct = ProductModel.fromJson(jsonData['data']);

        _log('Successfully created product: ${createdProduct.name}');

        return createdProduct;
      } else {
        _log("Failed to create product: ${response.reasonPhrase}");
        throw Exception("Failed to create product: ${response.reasonPhrase}");
      }
    } catch (e) {
      _log("Error while creating product: $e");
      throw Exception("Error while creating product: $e");
    }
  }

  /// Fetch single product by slug
  Future<ProductModel> fetchProductBySlug(String slug) async {
    final url = Uri.parse('$baseUrl/products/details/$slug');

    try {
      final response = await http.get(url);
      _log('GET /products/details/$slug response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final product = ProductModel.fromJson(jsonData['data']);

        _log('Successfully fetched product by slug: $slug');

        return product;
      } else {
        _log("Product not found for slug: $slug");
        throw Exception("Product not found");
      }
    } catch (e) {
      _log("Error while fetching product by slug $slug: $e");
      throw Exception("Error while fetching product by slug: $e");
    }
  }

  /// Search for products by query
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      _log('Empty search query provided');
      return [];
    }

    final Uri url = Uri.parse(
      '$baseUrl/products/all/search?q=${Uri.encodeComponent(query.trim())}',
    );

    try {
      final response = await http.get(url);
      _log('GET $url response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data'];
        final products = data.map((e) => ProductModel.fromJson(e)).toList();

        _log('Successfully searched products: found ${products.length} results for query: ${query.trim()}');

        return products;
      } else {
        _log("Failed to search products: ${response.reasonPhrase}");
        throw Exception("Failed to search products: ${response.reasonPhrase}");
      }
    } catch (e) {
      _log("Search error: $e");
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
      _log('GET $url response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data']['products'];
        final products = data.map((e) => ProductModel.fromJson(e)).toList();

        _log('Successfully fetched all products: ${products.length} products (page $page, limit $limit)');

        return products;
      } else {
        _log("Failed to load products: ${response.reasonPhrase}");
        throw Exception("Failed to load products: ${response.reasonPhrase}");
      }
    } catch (e) {
      _log("Error fetching products: $e");
      throw Exception("Error fetching products: $e");
    }
  }
}
