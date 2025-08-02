import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

// Import your data models
import '../data/Order_get_data.dart';
import '../data/order_model.dart';
import '../data/razor_pay.dart';

// Custom exception for API errors
class OrderServiceException implements Exception {
  final String message;
  final int statusCode; // HTTP status code or 0 for network error

  OrderServiceException(this.message, {this.statusCode = 0});

  @override
  String toString() => 'OrderServiceException: $message (Status: $statusCode)';
}

class OrderService extends GetxService {
  static const String _baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/orders';
  static const String _userRequestBaseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/request';
  final GetStorage _box = GetStorage();

  // ENHANCED: Timeout configurations
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  // Define a key for storing the last order ID
  static const String _lastOrderIdKey = 'lastOrderId';

  String? get _accessToken => _box.read('accessToken');

  void _log(String message) {
    print('[OrderService] $message');
  }

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

  // ENHANCED: Retry mechanism with exponential backoff
  Future<http.Response> _makeRequest(
      Future<http.Response> Function() requestFunction,
      String operationName, {
        int maxRetries = _maxRetries,
      }) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 1);

    while (attempt < maxRetries) {
      attempt++;
      _log('$operationName - Attempt $attempt/$maxRetries');

      try {
        final response = await requestFunction().timeout(
          Duration(seconds: 20 + (attempt * 10)), // Progressive timeout: 30s, 40s, 50s
          onTimeout: () {
            throw TimeoutException('Request timeout after ${20 + (attempt * 10)} seconds', null);
          },
        );

        // If successful, return immediately
        if (response.statusCode < 500) {
          return response;
        }

        // Server error, retry if we have attempts left
        if (attempt < maxRetries) {
          _log('$operationName - Server error (${response.statusCode}), retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
          continue;
        }

        return response;

      } on TimeoutException catch (e) {
        _log('$operationName - Timeout on attempt $attempt: ${e.message}');
        if (attempt < maxRetries) {
          _log('$operationName - Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }
        throw OrderServiceException(
          'Connection timeout after $maxRetries attempts. Please check your internet connection and try again.',
          statusCode: 408,
        );
      } on SocketException catch (e) {
        _log('$operationName - Network error on attempt $attempt: ${e.message}');
        if (attempt < maxRetries) {
          _log('$operationName - Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }
        throw OrderServiceException(
          'Network error: Please check your internet connection and try again.',
          statusCode: 0,
        );
      } on http.ClientException catch (e) {
        _log('$operationName - Client error on attempt $attempt: ${e.message}');
        if (attempt < maxRetries && e.message.contains('timeout')) {
          _log('$operationName - Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }
        throw OrderServiceException('Network error: ${e.message}', statusCode: 0);
      } catch (e) {
        _log('$operationName - Unexpected error on attempt $attempt: $e');
        if (attempt < maxRetries) {
          _log('$operationName - Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }
        throw OrderServiceException('Unexpected error: $e');
      }
    }

    throw OrderServiceException('Max retries exceeded for $operationName');
  }

  /// Fetches detailed information for a specific order by ID.
  Future<OrderModel> getOrderDetails({String? orderId}) async {
    String? idToFetch = orderId;
    _log("getOrderDetails called. Attempting to fetch ID: $orderId");

    // If no ID is passed, try to retrieve the MongoDB _id from GetStorage
    if (idToFetch == null || idToFetch.isEmpty) {
      idToFetch = _box.read(_lastOrderIdKey);
      _log("No ID passed. Trying from _lastOrderIdKey (MongoDB _id): $idToFetch");
      if (idToFetch == null || idToFetch.isEmpty) {
        throw OrderServiceException('No order ID provided and no last order ID found in storage.');
      }
    }

    final url = Uri.parse('$_baseUrl/details/$idToFetch');

    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for order details request: $e');
    }

    try {
      final response = await _makeRequest(
            () => http.get(url, headers: headers),
        'getOrderDetails',
      );

      final responseBody = jsonDecode(response.body);
      _log("getOrderDetails Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data')) {
          _log("Successfully fetched order details");
          return OrderModel.fromJson(responseBody['data'] as Map<String, dynamic>);
        } else {
          throw OrderServiceException(
            responseBody['message'] ?? 'Invalid response format for order details.',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw OrderServiceException(
          responseBody['message'] ?? 'Failed to fetch order details.',
          statusCode: response.statusCode,
        );
      }
    } on FormatException catch (e) {
      _log('Server response format error for order details: $e');
      throw OrderServiceException('Server response format error for order details: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error while fetching order details: $e');
      throw OrderServiceException('Unexpected error while fetching order details: $e');
    }
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
      final response = await _makeRequest(
            () => http.post(
          url,
          headers: headers,
          body: jsonEncode(orderRequest.toJson()),
        ),
        'placeCodOrder',
      );

      final responseBody = jsonDecode(response.body);
      _log("placeCodOrder Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data')) {
          final OrderModel order = OrderModel.fromJson(responseBody['data']['order'] as Map<String, dynamic>);
          await _box.write(_lastOrderIdKey, order.id);
          _log('COD Order MongoDB _id stored: ${order.id}');

          // Show success message to user
          Get.snackbar('Success', 'COD order placed successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);

          return order;
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
    } on FormatException catch (e) {
      _log('Server response format error during COD order placement: $e');
      throw OrderServiceException('Server response format error during COD order placement: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error occurred during COD order placement: $e');
      throw OrderServiceException('An unexpected error occurred during COD order placement: $e');
    }
  }

  // ENHANCED: Initiate online order with better timeout handling
  Future<Map<String, dynamic>> initiateOnlineOrder(CreateOrderRequestModel orderRequest) async {
    final url = Uri.parse('$_baseUrl/online/new');
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for online order initiation: $e');
    }

    try {
      final response = await _makeRequest(
            () => http.post(
          url,
          headers: headers,
          body: jsonEncode(orderRequest.toJson()),
        ),
        'initiateOnlineOrder',
        maxRetries: 2, // Reduce retries for payment initiation to avoid duplicate orders
      );

      final responseBody = jsonDecode(response.body);
      _log("initiateOnlineOrder Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data') && responseBody['data'] is Map<String, dynamic>) {
          final Map<String, dynamic> responseData = responseBody['data'] as Map<String, dynamic>;

          await _box.write('razorpay_init_response', responseData);
          _log('Razorpay init response stored: $responseData');

          // Store MongoDB _id if available from initiate response
          if (responseData.containsKey('order') && responseData['order'] is Map<String, dynamic> && responseData['order'].containsKey('_id')) {
            await _box.write(_lastOrderIdKey, responseData['order']['_id']);
            _log('Online Order MongoDB _id stored: ${responseData['order']['_id']}');
          } else {
            _log('Warning: Online order initiation response did not contain expected MongoDB _id. Details fetching for this order might fail.');
          }

          // Show success message to user
          Get.snackbar('Success', 'Payment initiated successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);

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
    } on FormatException catch (e) {
      _log('Server response format error during online order initiation: $e');
      throw OrderServiceException('Server response format error during online order initiation: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error occurred during online order initiation: $e');
      throw OrderServiceException('An unexpected error occurred during online order initiation: $e');
    }
  }

  Future<OrderModel> verifyRazorpayPayment(RazorpayVerifyRequest verifyRequest) async {
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
      final response = await _makeRequest(
            () => http.post(
          url,
          headers: headers,
          body: jsonEncode(verifyRequest.toJson()),
        ),
        'verifyRazorpayPayment',
      );

      final responseBody = jsonDecode(response.body);
      _log("verifyRazorpayPayment Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data')) {
          await _box.remove('razorpay_init_response');
          _log('Razorpay init response cleared from storage.');

          final OrderModel order = OrderModel.fromJson(responseBody['data'] as Map<String, dynamic>);
          await _box.write(_lastOrderIdKey, order.id);
          _log('Verified Online Order MongoDB _id stored: ${order.id}');

          // Show success message to user
          Get.snackbar('Success', 'Payment verified and order placed successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);

          return order;
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
    } on FormatException catch (e) {
      _log('Server response format error during Razorpay verification: $e');
      throw OrderServiceException('Server response format error during Razorpay verification: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error occurred during Razorpay verification: $e');
      throw OrderServiceException('An unexpected error occurred during Razorpay verification: $e');
    }
  }

  /// Fetches a list of orders specific to the authenticated user.
  Future<List<OrderModel>> getUserOrders() async {
    final url = Uri.parse('$_baseUrl/user');
    Map<String, String> headers;
    try {
      headers = _getHeaders();
    } on OrderServiceException {
      rethrow;
    } catch (e) {
      throw OrderServiceException('Failed to prepare headers for fetching orders: $e');
    }

    try {
      final response = await _makeRequest(
            () => http.get(url, headers: headers),
        'getUserOrders',
      );

      final responseBody = jsonDecode(response.body);
      _log('getUserOrders Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true && responseBody.containsKey('data') && responseBody['data'] is List) {
          final orders = (responseBody['data'] as List)
              .map((itemJson) => OrderModel.fromJson(itemJson as Map<String, dynamic>))
              .toList();

          _log('Successfully fetched ${orders.length} orders');
          return orders;
        } else if (responseBody['success'] == true && responseBody['data'] is List && (responseBody['data'] as List).isEmpty) {
          _log('No orders found for user');
          return [];
        } else {
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
    } on FormatException catch (e) {
      _log('Server response format error: $e');
      throw OrderServiceException('Server response format error: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error occurred: $e');
      throw OrderServiceException('An unexpected error occurred: $e');
    }
  }

  // ENHANCED: Request methods with better error handling

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
      final response = await _makeRequest(
            () => http.post(
          url,
          headers: headers,
          body: jsonEncode({
            "reason": reason,
            "orderId": orderId,
          }),
        ),
        'requestCancel',
      );

      final responseBody = jsonDecode(response.body);
      _log("requestCancel Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          // Show success message to user
          Get.snackbar('Success', 'Cancel request submitted successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);

          return responseBody as Map<String, dynamic>;
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
    } on FormatException catch (e) {
      _log('Server response format error during cancel request: $e');
      throw OrderServiceException('Server response format error during cancel request: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error occurred during cancel request: $e');
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
      final response = await _makeRequest(
            () => http.post(
          url,
          headers: headers,
          body: jsonEncode({
            "reason": reason,
            "orderId": orderId,
          }),
        ),
        'requestWarranty',
      );

      final responseBody = jsonDecode(response.body);
      _log("requestWarranty Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          // Show success message to user
          Get.snackbar('Success', 'Warranty request submitted successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);

          return responseBody as Map<String, dynamic>;
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
    } on FormatException catch (e) {
      _log('Server response format error during warranty request: $e');
      throw OrderServiceException('Server response format error during warranty request: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error occurred during warranty request: $e');
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
      final response = await _makeRequest(
            () => http.post(
          url,
          headers: headers,
          body: jsonEncode({
            "reason": reason,
            "orderId": orderId,
          }),
        ),
        'requestReturn',
      );

      final responseBody = jsonDecode(response.body);
      _log("requestReturn Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          // Show success message to user
          Get.snackbar('Success', 'Return request submitted successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);

          return responseBody as Map<String, dynamic>;
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
    } on FormatException catch (e) {
      _log('Server response format error during return request: $e');
      throw OrderServiceException('Server response format error during return request: $e', statusCode: 0);
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      _log('Unexpected error occurred during return request: $e');
      throw OrderServiceException('An unexpected error occurred during return request: $e');
    }
  }

  // ADDED: Network health check method
  Future<bool> checkNetworkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _getHeaders(requireAuth: false),
      ).timeout(const Duration(seconds: 10));

      _log('Network health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      _log('Network health check failed: $e');
      return false;
    }
  }

  // ADDED: Clear stored data method
  Future<void> clearStoredData() async {
    await _box.remove(_lastOrderIdKey);
    await _box.remove('razorpay_init_response');
    _log('Cleared stored order data');
  }
}
