import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart'; // Import GetX for potential error handling/navigation

class CartService {
  final String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1';
  final box = GetStorage();

  // Helper to get common headers
  Map<String, String> _getHeaders() {
    // CORRECTED: Read accessToken directly from the 'accessToken' key
    String? accessToken = box.read('accessToken');

    print('CartService: Attempting to send Access Token: ${accessToken != null ? "Present" : "NULL"}'); // Debugging

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken', // Attach the token
    };
  }

  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required String cartId,
    required String variantName,
  }) async {
    try {
      // Ensure cartId is valid before proceeding
      if (cartId == null || cartId.isEmpty) {
        return {'success': false, 'message': 'Cart ID is missing or invalid.'};
      }

      // Check if the API endpoint is /carts/add-to-cart/:cartId or /cart/add
      // Based on previous discussions, it was /carts/add-to-cart/:cartId
      // If it's /cart/add, ensure your backend correctly uses the cartId from the body.
      // For this example, I'll use the /cart/add endpoint as per your service code.
      final url = Uri.parse('$baseUrl/cart/add'); // Endpoint as per your code

      final body = jsonEncode({
        'productId': productId,
        'cartId': cartId, // Ensure your backend expects cartId in the body for /cart/add
        'variantName': variantName,
        'quantity': 1, // Assuming add implies increasing quantity by 1
      });

      final response = await http.post(url, headers: _getHeaders(), body: body);

      // Detailed logging for debugging API responses
      print('Add to Cart Response Status: ${response.statusCode}');
      print('Add to Cart Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Specific handling for 401 Unauthorized
        // You might want to trigger a re-login or show a specific message
        // Get.offAll(() => LoginScreen()); // Example: navigate to login
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else {
        // Attempt to parse error message from backend if available
        String errorMessage = 'Failed with status code ${response.statusCode}.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          // If JSON parsing fails, use generic message
          print('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Add to cart error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> removeFromCart({
    required String productId,
    required String cartId,
    required String variantName,
  }) async {
    try {
      // Ensure cartId is valid before proceeding
      if (cartId == null || cartId.isEmpty) {
        return {'success': false, 'message': 'Cart ID is missing or invalid.'};
      }

      final url = Uri.parse('$baseUrl/cart/remove'); // Endpoint as per your code

      final request = http.Request('DELETE', url); // Still using DELETE with body
      request.headers.addAll(_getHeaders());
      request.body = jsonEncode({
        'productId': productId,
        'cartId': cartId, // Ensure backend expects cartId in body for /cart/remove DELETE
        'variantName': variantName,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Detailed logging for debugging API responses
      print('Remove from Cart Response Status: ${response.statusCode}');
      print('Remove from Cart Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else {
        String errorMessage = 'Failed with status code ${response.statusCode}.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          print('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Remove from cart error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // You might also want a method to fetch the entire cart (e.g., on cart screen load)
  Future<Map<String, dynamic>> fetchCart({required String cartId}) async {
    try {
      if (cartId == null || cartId.isEmpty) {
        return {'success': false, 'message': 'Cart ID is missing for fetch.'};
      }
      final url = Uri.parse('$baseUrl/carts/$cartId'); // Assuming a GET endpoint like /api/v1/carts/:cartId
      final response = await http.get(url, headers: _getHeaders());

      print('Fetch Cart Response Status: ${response.statusCode}');
      print('Fetch Cart Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else {
        String errorMessage = 'Failed to fetch cart with status code ${response.statusCode}.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          print('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Fetch cart error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred during cart fetch: ${e.toString()}',
      };
    }
  }
}