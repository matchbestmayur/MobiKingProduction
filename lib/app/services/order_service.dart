import 'dart:convert';
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
      final response = await http.get(url, headers: headers);
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
    } on http.ClientException catch (e) {
      _log('Network error while fetching order details: ${e.message}');
      throw OrderServiceException('Network error while fetching order details: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error for order details: $e');
      throw OrderServiceException('Server response format error for order details: $e', statusCode: 0);
    } catch (e) {
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
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(orderRequest.toJson()),
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
    } on http.ClientException catch (e) {
      _log('Network error during COD order placement: ${e.message}');
      throw OrderServiceException('Network error during COD order placement: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error during COD order placement: $e');
      throw OrderServiceException('Server response format error during COD order placement: $e', statusCode: 0);
    } catch (e) {
      _log('Unexpected error occurred during COD order placement: $e');
      throw OrderServiceException('An unexpected error occurred during COD order placement: $e');
    }
  }

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
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(orderRequest.toJson()),
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
    } on http.ClientException catch (e) {
      _log('Network error during online order initiation: ${e.message}');
      throw OrderServiceException('Network error during online order initiation: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error during online order initiation: $e');
      throw OrderServiceException('Server response format error during online order initiation: $e', statusCode: 0);
    } catch (e) {
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
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(verifyRequest.toJson()),
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
    } on http.ClientException catch (e) {
      _log('Network error during Razorpay verification: ${e.message}');
      throw OrderServiceException('Network error during Razorpay verification: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error during Razorpay verification: $e');
      throw OrderServiceException('Server response format error during Razorpay verification: $e', statusCode: 0);
    } catch (e) {
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
      final response = await http.get(url, headers: headers);
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
    } on http.ClientException catch (e) {
      _log('Network error: ${e.message}');
      throw OrderServiceException('Network error: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error: $e');
      throw OrderServiceException('Server response format error: $e', statusCode: 0);
    } catch (e) {
      _log('Unexpected error occurred: $e');
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
    } on http.ClientException catch (e) {
      _log('Network error during cancel request: ${e.message}');
      throw OrderServiceException('Network error during cancel request: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error during cancel request: $e');
      throw OrderServiceException('Server response format error during cancel request: $e', statusCode: 0);
    } catch (e) {
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
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "reason": reason,
          "orderId": orderId,
        }),
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
    } on http.ClientException catch (e) {
      _log('Network error during warranty request: ${e.message}');
      throw OrderServiceException('Network error during warranty request: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error during warranty request: $e');
      throw OrderServiceException('Server response format error during warranty request: $e', statusCode: 0);
    } catch (e) {
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
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "reason": reason,
          "orderId": orderId,
        }),
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
    } on http.ClientException catch (e) {
      _log('Network error during return request: ${e.message}');
      throw OrderServiceException('Network error during return request: ${e.message}', statusCode: 0);
    } on FormatException catch (e) {
      _log('Server response format error during return request: $e');
      throw OrderServiceException('Server response format error during return request: $e', statusCode: 0);
    } catch (e) {
      _log('Unexpected error occurred during return request: $e');
      throw OrderServiceException('An unexpected error occurred during return request: $e');
    }
  }
}
