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
    print('QueryService: Auth token set in Dio headers: $_authToken');
  }

  Future<T> _handleDioResponse<T>(
      Response response,
      T Function(dynamic jsonData) dataParser,
      ) async {
    print('QueryService: _handleDioResponse - Processing response with status: ${response.statusCode}');

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final dynamic rawResponseData = response.data;

      if (rawResponseData is String &&
          !rawResponseData.trim().startsWith('{') &&
          !rawResponseData.trim().startsWith('[')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Backend returned a non-JSON string: "$rawResponseData". Expected JSON.',
        );
      }

      if (rawResponseData is Map<String, dynamic>) {
        if (rawResponseData.containsKey('statusCode') &&
            rawResponseData.containsKey('message') &&
            rawResponseData.containsKey('data')) {
          final apiResponse = ApiResponse<T>.fromJson(rawResponseData, dataParser);
          if (apiResponse.statusCode! >= 200 && apiResponse.statusCode! < 300) {
            return apiResponse.data as T;

          } else {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'API Error (${apiResponse.statusCode}): ${apiResponse.message}',
            );
          }
        } else {
          try {
            return dataParser(rawResponseData);
          } catch (e) {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'Received JSON object, but could not parse with dataParser: $e. Data: $rawResponseData',
            );
          }
        }
      } else if (rawResponseData is List<dynamic>) {
        try {
          return dataParser(rawResponseData);
        } catch (e) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Received JSON list, but could not parse with dataParser: $e. Data: $rawResponseData',
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Unexpected root response data type: ${rawResponseData.runtimeType}. Content: $rawResponseData',
        );
      }
    } else {
      String errorMessage = 'Unknown HTTP Error';
      if (response.data is Map && response.data.containsKey('message')) {
        final dynamic backendMessage = response.data['message'];
        if (backendMessage is String) {
          errorMessage = backendMessage;
        } else if (backendMessage is Map<String, dynamic>) {
          errorMessage = 'Error details: ${jsonEncode(backendMessage)}';
        } else {
          errorMessage = backendMessage.toString();
        }
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
    String userFacingErrorMessage = 'An unexpected error occurred.';

    if (e.response != null && e.response!.data != null) {
      final dynamic responseData = e.response!.data;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('message')) {
          final dynamic backendMessage = responseData['message'];
          if (backendMessage is String) {
            userFacingErrorMessage = backendMessage;
          } else if (backendMessage is Map<String, dynamic>) {
            userFacingErrorMessage = 'Error details: ${jsonEncode(backendMessage)}';
          } else {
            userFacingErrorMessage = backendMessage.toString();
          }
        } else if (responseData.containsKey('error')) {
          final dynamic backendError = responseData['error'];
          if (backendError is String) {
            userFacingErrorMessage = backendError;
          } else {
            userFacingErrorMessage = backendError.toString();
          }
        } else {
          userFacingErrorMessage = 'Server response: ${jsonEncode(responseData)}';
        }
      } else if (responseData is String) {
        userFacingErrorMessage = responseData;
      } else {
        userFacingErrorMessage = 'Unexpected server response format: ${responseData.runtimeType}';
      }
    } else {
      userFacingErrorMessage = e.message ?? 'No response from server.';
    }
    return userFacingErrorMessage;
  }

  Future<QueryModel> raiseQuery({
    required String title,
    required String message,
    String? orderId,
  }) async {
    final url = '$_baseUrl/queries/raiseQuery';
    final requestBody = RaiseQueryRequestModel(
      title: title,
      description: message,
      orderId: orderId,
    ).toJson();

    try {
      final response = await _dio.post(url, data: requestBody);
      return _handleDioResponse(response, (json) => QueryModel.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in raiseQuery: $errorMsg');
      throw Exception('Failed to raise query: $errorMsg');
    }
  }

  Future<QueryModel> rateQuery({
    required String queryId,
    required int rating,
    String? review,
  }) async {
    final url = '$_baseUrl/queries/$queryId/rate';
    final requestBody = RateQueryRequestModel(rating: rating, review: review).toJson();

    try {
      final response = await _dio.post(url, data: requestBody);
      return _handleDioResponse(response, (json) => QueryModel.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in rateQuery: $errorMsg');
      throw Exception('Failed to rate query: $errorMsg');
    }
  }

  Future<QueryModel> replyToQuery({
    required String queryId,
    required String replyText,
  }) async {
    final url = '$_baseUrl/queries/reply';
    final requestBody = ReplyQueryRequestModel(queryId: queryId, message: replyText).toJson();

    try {
      final response = await _dio.post(url, data: requestBody);
      return _handleDioResponse(response, (json) => QueryModel.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in replyToQuery: $errorMsg');
      throw Exception('Failed to reply to query: $errorMsg');
    }
  }

  Future<List<QueryModel>> getMyQueries() async {
    final url = '$_baseUrl/queries/my';

    try {
      final response = await _dio.get(url);

      return _handleDioResponse(
        response,
            (jsonData) {
          if (jsonData is List) {
            // If response is a list of queries
            return jsonData
                .map((e) => QueryModel.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (jsonData is Map<String, dynamic>) {
            // If response is a single query object
            return [QueryModel.fromJson(jsonData)];
          } else {
            throw Exception("Unexpected response format for queries.");
          }
        },
      );
    } on DioException catch (e) {
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in getMyQueries: $errorMsg');
      throw Exception('Failed to load queries: $errorMsg');
    }
  }


  Future<QueryModel> getQueryById(String queryId) async {
    final url = '$_baseUrl/queries/$queryId';
    try {
      final response = await _dio.get(url);
      return _handleDioResponse(response, (json) => QueryModel.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in getQueryById: $errorMsg');
      throw Exception('Failed to get query by ID: $errorMsg');
    }
  }

}
