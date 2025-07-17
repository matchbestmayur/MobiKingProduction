import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

// Import your data models
import '../data/Order_get_data.dart'; // Assuming this contains CreateOrderRequestModel etc.
import '../data/order_model.dart';
import '../data/razor_pay.dart'; // The full OrderModel (Response Model)


// Custom exception for API errors
class OrderServiceException implements Exception {
  final String message;
  final int statusCode; // HTTP status code or 0 for network error

  OrderServiceException(this.message, {this.statusCode = 0});

  @override
  String toString() => 'OrderServiceException: $message (Status: $statusCode)';
}

class OrderService extends GetxService {
  static const String _baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/orders'; // Your actual base URL
  static const String _userRequestBaseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/request'; // Base URL for user requests
  final GetStorage _box = GetStorage();

  String? get _accessToken => _box.read('accessToken');

  Map<String, String> _getHeaders({bool requireAuth = true}) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      final token = _accessToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw OrderServiceException('Authentication required. Access token not found.', statusCode: 401);
      }
    }
    return headers;
  }

  /// Places a COD order.
  Future<OrderModel> placeCodOrder(CreateOrderRequestModel orderRequest) async {
    final url = Uri.parse('$_baseUrl/cod/new');
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers: $e');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(orderRequest.toJson()),
      );

      final responseBody = jsonDecode(response.body);
      print("OrderService - placeCodOrder Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data')) {
          return OrderModel.fromJson(responseBody['data'] as Map<String, dynamic>);
        } else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Failed to place COD order: Invalid success status or data format.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'COD order placement failed.',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw OrderServiceException('Network error during COD order placement: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      throw OrderServiceException('Server response format error during COD order placement: $e', statusCode: 0);
    } catch (e) {
      throw OrderServiceException('An unexpected error occurred during COD order placement: $e');
    }
  }

  Future<Map<String, dynamic>> initiateOnlineOrder(CreateOrderRequestModel orderRequest) async {
    final url = Uri.parse('$_baseUrl/online/new'); // Use your specific endpoint for initiation
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for online order initiation: $e');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(orderRequest.toJson()),
      );

      final responseBody = jsonDecode(response.body);
      print("OrderService - initiateOnlineOrder Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data') && responseBody['data'] is Map<String, dynamic>) {
          final Map<String, dynamic> responseData = responseBody['data'] as Map<String, dynamic>;

          // --- Store the entire 'data' map in GetStorage ---
          await _box.write('razorpay_init_response', responseData);
          print('Razorpay init response stored: $responseData');
          // --- End Store ---

          return responseData;
        } else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Failed to initiate online order: Invalid success status or data format. Expected data map.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'Online order initiation failed.',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw OrderServiceException('Network error during online order initiation: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      throw OrderServiceException('Server response format error during online order initiation: $e', statusCode: 0);
    } catch (e) {
      throw OrderServiceException('An unexpected error occurred during online order initiation: $e');
    }
  }


  Future<OrderModel> verifyRazorpayPayment(RazorpayVerifyRequest verifyRequest) async {
    // Corrected to use _baseUrl for consistency
    final url = Uri.parse('$_baseUrl/online/verify');
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for Razorpay verification: $e');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(verifyRequest.toJson()),
      );

      final responseBody = jsonDecode(response.body);
      print("OrderService - verifyRazorpayPayment Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data')) {
          // Clear the stored Razorpay init response after successful verification
          await _box.remove('razorpay_init_response');
          print('Razorpay init response cleared from storage.');
          return OrderModel.fromJson(responseBody['data'] as Map<String, dynamic>);
        } else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Razorpay verification failed: Invalid success status or data format.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'Razorpay verification failed on backend.',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw OrderServiceException('Network error during Razorpay verification: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      throw OrderServiceException('Server response format error during Razorpay verification: $e', statusCode: 0);
    } catch (e) {
      throw OrderServiceException('An unexpected error occurred during Razorpay verification: $e');
    }
  }

  /// Fetches a list of orders specific to the authenticated user.
  Future<List<OrderModel>> getUserOrders() async {
    final url = Uri.parse('$_baseUrl/user'); // Endpoint for user-specific orders
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for fetching orders: $e');
    }

    try {
      final response = await http.get(url, headers: headers);
      final responseBody = jsonDecode(response.body);

      print('OrderService - getUserOrders Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data') && responseBody['data'] is List) {
          return (responseBody['data'] as List)
              .map((itemJson) => OrderModel.fromJson(itemJson as Map<String, dynamic>))
              .toList();
        } else if (responseBody['success'] == true && responseBody['data'] is List && (responseBody['data'] as List).isEmpty) {
          return [];
        }
        else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Failed to load orders: Invalid success status or data format.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'Failed to fetch order history.',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw OrderServiceException('Network error: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      throw OrderServiceException('Server response format error: $e', statusCode: 0);
    } catch (e) {
      throw OrderServiceException('An unexpected error occurred: $e');
    }
  }

  // --- NEW METHODS FOR ORDER REQUESTS ---

  /// Sends a request to the backend to cancel an order.
  Future<Map<String, dynamic>> requestCancel(String orderId, String reason) async {
    final url = Uri.parse('$_userRequestBaseUrl/cancel');
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for cancel request: $e');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "reason": reason,
          "orderId": orderId,
        }),
      );

      final responseBody = jsonDecode(response.body);
      print("OrderService - requestCancel Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          return responseBody as Map<String, dynamic>; // Return the full response body
        } else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Failed to send cancel request.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'Cancel request failed on backend.',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw OrderServiceException('Network error during cancel request: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      throw OrderServiceException('Server response format error during cancel request: $e', statusCode: 0);
    } catch (e) {
      throw OrderServiceException('An unexpected error occurred during cancel request: $e');
    }
  }

  /// Sends a request to the backend for order warranty.
  Future<Map<String, dynamic>> requestWarranty(String orderId, String reason) async {
    final url = Uri.parse('$_userRequestBaseUrl/warranty');
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for warranty request: $e');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "reason": reason,
          "orderId": orderId,
        }),
      );

      final responseBody = jsonDecode(response.body);
      print("OrderService - requestWarranty Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          return responseBody as Map<String, dynamic>; // Return the full response body
        } else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Failed to send warranty request.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'Warranty request failed on backend.',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw OrderServiceException('Network error during warranty request: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      throw OrderServiceException('Server response format error during warranty request: $e', statusCode: 0);
    } catch (e) {
      throw OrderServiceException('An unexpected error occurred during warranty request: $e');
    }
  }

  /// Sends a request to the backend for order return.
  Future<Map<String, dynamic>> requestReturn(String orderId, String reason) async {
    final url = Uri.parse('$_userRequestBaseUrl/return');
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for return request: $e');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "reason": reason,
          "orderId": orderId,
        }),
      );

      final responseBody = jsonDecode(response.body);
      print("OrderService - requestReturn Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          return responseBody as Map<String, dynamic>; // Return the full response body
        } else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Failed to send return request.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'Return request failed on backend.',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw OrderServiceException('Network error during return request: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      throw OrderServiceException('Server response format error during return request: $e', statusCode: 0);
    } catch (e) {
      throw OrderServiceException('An unexpected error occurred during return request: $e');
    }
  }
}