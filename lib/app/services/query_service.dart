import 'dart:convert';
import 'package:dio/dio.dart';
import '../data/QueryModel.dart';

class QueryService {
  final Dio _dio;
  final String _baseUrl = "https://mobiking-e-commerce-backend-prod.vercel.app/api/v1";
  String? _authToken;

  QueryService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('DIO LOG: $obj'),
      ),
    );
  }

  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $_authToken';
  }

  /// Internal generic response handler
  Future<T> _handleDioResponse<T>(Response response, T Function(dynamic jsonData) dataParser) async {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data;
      if (data is String && (!data.trim().startsWith('{') && !data.trim().startsWith('['))) {
        // Backend mistake: returned plain string instead of JSON
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Backend did not return JSON. Data: $data',
        );
      }
      // API usually wraps with statusCode/message/data, else parse direct
      if (data is Map<String, dynamic>) {
        if (data.containsKey('statusCode') && data.containsKey('data')) {
          final apiData = data['data'];
          return dataParser(apiData);
        } else {
          return dataParser(data);
        }
      } else if (data is List) {
        return dataParser(data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Unexpected root type: ${data.runtimeType}',
        );
      }
    } else {
      String errorMessage = 'Unknown HTTP error';
      if (response.data is Map && response.data.containsKey('message')) {
        errorMessage = response.data['message'].toString();
      } else if (response.data != null) {
        errorMessage = response.data.toString();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: errorMessage,
      );
    }
  }

  String _getDioErrorMessage(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) {
          return data['message'].toString();
        } else if (data.containsKey('error')) {
          return data['error'].toString();
        }
      } else if (data is String) {
        return data;
      }
      return 'Server error: ${jsonEncode(data)}';
    } else {
      return e.message ?? 'No response from server.';
    }
  }

  // --- MAIN QUERY FUNCTIONS ---

  Future<QueryModel> raiseQuery({
    required String title,
    required String message,
    String? orderId,
  }) async {
    final url = '$_baseUrl/queries/raiseQuery';
    final requestBody = {
      "title": title,
      "description": message,
      if (orderId != null) "orderId": orderId,
    };
    try {
      final response = await _dio.post(url, data: requestBody);
      return await _handleDioResponse(response, (json) => QueryModel.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      throw Exception('Failed to raise query: ${_getDioErrorMessage(e)}');
    } catch (e) {
      throw Exception('Failed to raise query: $e');
    }
  }

  Future<QueryModel> rateQuery({
    required String queryId,
    required int rating,
    String? review,
  }) async {
    final url = '$_baseUrl/queries/rate';
    final requestBody = {
      'queryId': queryId,
      'rating': rating,
      if (review != null) 'review': review,
    };
    try {
      final response = await _dio.post(url, data: requestBody);
      return await _handleDioResponse(response, (json) => QueryModel.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      throw Exception('Failed to rate query: ${_getDioErrorMessage(e)}');
    } catch (e) {
      throw Exception('Failed to rate query: $e');
    }
  }

  Future<QueryModel> replyToQuery({
    required String queryId,
    required String replyText,
  }) async {
    final url = '$_baseUrl/queries/reply';
    final requestBody = {
      'queryId': queryId,
      'message': replyText,
    };
    try {
      final response = await _dio.post(url, data: requestBody);
      return await _handleDioResponse(response, (json) => QueryModel.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      throw Exception('Failed to reply to query: ${_getDioErrorMessage(e)}');
    } catch (e) {
      throw Exception('Failed to reply to query: $e');
    }
  }

  Future<List<QueryModel>> getMyQueries() async {
    final url = '$_baseUrl/queries/my';
    try {
      final response = await _dio.get(url);
      return await _handleDioResponse(response, (jsonData) {
        if (jsonData is List) {
          return jsonData
              .map((e) => QueryModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (jsonData is Map<String, dynamic>) {
          // If backend returns single object incorrectly
          return [QueryModel.fromJson(jsonData)];
        } else {
          throw Exception("Malformed response from queries/my!");
        }
      });
    } on DioException catch (e) {
      throw Exception('Failed to load queries: ${_getDioErrorMessage(e)}');
    } catch (e) {
      throw Exception('Failed to load queries: $e');
    }
  }

  Future<QueryModel> getQueryById(String queryId) async {
    final url = '$_baseUrl/queries/$queryId';
    try {
      final response = await _dio.get(url);
      return await _handleDioResponse(
          response,
              (json) => QueryModel.fromJson(json as Map<String, dynamic>)
      );
    } on DioException catch (e) {
      throw Exception('Failed to get query by ID: ${_getDioErrorMessage(e)}');
    } catch (e) {
      throw Exception('Failed to get query by ID: $e');
    }
  }
}
