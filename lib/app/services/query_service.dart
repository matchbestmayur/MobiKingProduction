import 'dart:convert';
import 'package:dio/dio.dart';
import '../data/QueryModel.dart';

class QueryService {
  final Dio _dio;
  final String _baseUrl = "https://mobiking-e-commerce-backend-prod.vercel.app/api/v1";
  String? _authToken;

  QueryService({Dio? dio}) : _dio = dio ?? Dio() {
    print('QueryService: Initializing QueryService with base URL: $_baseUrl');
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
    print('QueryService: Dio interceptors added successfully');
  }

  void setAuthToken(String token) {
    print('QueryService: Setting auth token - Token length: ${token.length}');
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $_authToken';
    print('QueryService: Auth token set in Dio headers: $_authToken');
    print('QueryService: Current Dio headers: ${_dio.options.headers}');
  }

  Future<T> _handleDioResponse<T>(
      Response response,
      T Function(dynamic jsonData) dataParser,
      ) async {
    print('QueryService: _handleDioResponse - Starting response processing');
    print('QueryService: Response status code: ${response.statusCode}');
    print('QueryService: Response headers: ${response.headers}');
    print('QueryService: Raw response data type: ${response.data.runtimeType}');
    print('QueryService: Raw response data: ${response.data}');

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      print('QueryService: Response status code is successful (${response.statusCode})');
      final dynamic rawResponseData = response.data;

      if (rawResponseData is String &&
          !rawResponseData.trim().startsWith('{') &&
          !rawResponseData.trim().startsWith('[')) {
        print('QueryService: ERROR - Backend returned non-JSON string: "$rawResponseData"');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Backend returned a non-JSON string: "$rawResponseData". Expected JSON.',
        );
      }

      if (rawResponseData is Map<String, dynamic>) {
        print('QueryService: Response data is a Map<String, dynamic>');
        print('QueryService: Map keys: ${rawResponseData.keys.toList()}');

        if (rawResponseData.containsKey('statusCode') &&
            rawResponseData.containsKey('message') &&
            rawResponseData.containsKey('data')) {
          print('QueryService: Response has API wrapper structure (statusCode, message, data)');
          print('QueryService: API statusCode: ${rawResponseData['statusCode']}');
          print('QueryService: API message: ${rawResponseData['message']}');
          print('QueryService: API data: ${rawResponseData['data']}');

          final apiResponse = ApiResponse<T>.fromJson(rawResponseData, dataParser);
          print('QueryService: ApiResponse parsed successfully');

          if (apiResponse.statusCode! >= 200 && apiResponse.statusCode! < 300) {
            print('QueryService: API response status is successful (${apiResponse.statusCode})');
            print('QueryService: Returning parsed data: ${apiResponse.data}');
            return apiResponse.data as T;
          } else {
            print('QueryService: ERROR - API response status is not successful (${apiResponse.statusCode})');
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'API Error (${apiResponse.statusCode}): ${apiResponse.message}',
            );
          }
        } else {
          print('QueryService: Response does not have API wrapper, parsing directly with dataParser');
          try {
            final result = dataParser(rawResponseData);
            print('QueryService: Direct parsing successful: $result');
            return result;
          } catch (e) {
            print('QueryService: ERROR - Direct parsing failed: $e');
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'Received JSON object, but could not parse with dataParser: $e. Data: $rawResponseData',
            );
          }
        }
      } else if (rawResponseData is List<dynamic>) {
        print('QueryService: Response data is a List<dynamic>');
        print('QueryService: List length: ${rawResponseData.length}');
        try {
          final result = dataParser(rawResponseData);
          print('QueryService: List parsing successful: $result');
          return result;
        } catch (e) {
          print('QueryService: ERROR - List parsing failed: $e');
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Received JSON list, but could not parse with dataParser: $e. Data: $rawResponseData',
          );
        }
      } else {
        print('QueryService: ERROR - Unexpected root response data type: ${rawResponseData.runtimeType}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Unexpected root response data type: ${rawResponseData.runtimeType}. Content: $rawResponseData',
        );
      }
    } else {
      print('QueryService: ERROR - Response status code is not successful: ${response.statusCode}');
      String errorMessage = 'Unknown HTTP Error';
      if (response.data is Map && response.data.containsKey('message')) {
        final dynamic backendMessage = response.data['message'];
        print('QueryService: Backend message found: $backendMessage (type: ${backendMessage.runtimeType})');
        if (backendMessage is String) {
          errorMessage = backendMessage;
        } else if (backendMessage is Map<String, dynamic>) {
          errorMessage = 'Error details: ${jsonEncode(backendMessage)}';
        } else {
          errorMessage = backendMessage.toString();
        }
      } else if (response.data != null) {
        print('QueryService: Using response.data as error message: ${response.data}');
        errorMessage = response.data.toString();
      }
      print('QueryService: Final error message: $errorMessage');
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: errorMessage,
      );
    }
  }

  String _getDioErrorMessage(DioException e) {
    print('QueryService: _getDioErrorMessage - Processing DioException');
    print('QueryService: DioException type: ${e.type}');
    print('QueryService: DioException message: ${e.message}');
    print('QueryService: DioException response: ${e.response}');

    String userFacingErrorMessage = 'An unexpected error occurred.';

    if (e.response != null && e.response!.data != null) {
      print('QueryService: DioException has response data');
      final dynamic responseData = e.response!.data;
      print('QueryService: Response data type: ${responseData.runtimeType}');
      print('QueryService: Response data content: $responseData');

      if (responseData is Map<String, dynamic>) {
        print('QueryService: Response data is Map, checking for message/error keys');
        if (responseData.containsKey('message')) {
          final dynamic backendMessage = responseData['message'];
          print('QueryService: Found message key: $backendMessage (type: ${backendMessage.runtimeType})');
          if (backendMessage is String) {
            userFacingErrorMessage = backendMessage;
          } else if (backendMessage is Map<String, dynamic>) {
            userFacingErrorMessage = 'Error details: ${jsonEncode(backendMessage)}';
          } else {
            userFacingErrorMessage = backendMessage.toString();
          }
        } else if (responseData.containsKey('error')) {
          final dynamic backendError = responseData['error'];
          print('QueryService: Found error key: $backendError (type: ${backendError.runtimeType})');
          if (backendError is String) {
            userFacingErrorMessage = backendError;
          } else {
            userFacingErrorMessage = backendError.toString();
          }
        } else {
          print('QueryService: No message/error key found, using entire response');
          userFacingErrorMessage = 'Server response: ${jsonEncode(responseData)}';
        }
      } else if (responseData is String) {
        print('QueryService: Response data is String: $responseData');
        userFacingErrorMessage = responseData;
      } else {
        print('QueryService: Unexpected response data format: ${responseData.runtimeType}');
        userFacingErrorMessage = 'Unexpected server response format: ${responseData.runtimeType}';
      }
    } else {
      print('QueryService: No response data available, using exception message');
      userFacingErrorMessage = e.message ?? 'No response from server.';
    }

    print('QueryService: Final error message: $userFacingErrorMessage');
    return userFacingErrorMessage;
  }

  Future<QueryModel> raiseQuery({
    required String title,
    required String message,
    String? orderId,
  }) async {
    print('QueryService: raiseQuery - Starting');
    print('QueryService: Title: $title');
    print('QueryService: Message: $message');
    print('QueryService: OrderId: $orderId');

    final url = '$_baseUrl/queries/raiseQuery';
    print('QueryService: Request URL: $url');

    final requestBody = RaiseQueryRequestModel(
      title: title,
      description: message,
      orderId: orderId,
    ).toJson();

    print('QueryService: Request body: $requestBody');
    print('QueryService: Auth token present: ${_authToken != null}');

    try {
      print('QueryService: Making POST request...');
      final response = await _dio.post(url, data: requestBody);
      print('QueryService: POST request completed successfully');

      final result = await _handleDioResponse(response, (json) {
        print('QueryService: Parsing response as QueryModel');
        return QueryModel.fromJson(json as Map<String, dynamic>);
      });

      print('QueryService: raiseQuery completed successfully: $result');
      return result;
    } on DioException catch (e) {
      print('QueryService: DioException caught in raiseQuery');
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in raiseQuery: $errorMsg');
      throw Exception('Failed to raise query: $errorMsg');
    } catch (e) {
      print('QueryService: Unexpected exception in raiseQuery: $e');
      throw Exception('Failed to raise query: $e');
    }
  }

  Future<QueryModel> rateQuery({
    required String queryId,
    required int rating,
    String? review,
  }) async {
    print('QueryService: rateQuery - Starting');
    print('QueryService: QueryId: $queryId');
    print('QueryService: Rating: $rating');
    print('QueryService: Review: $review');

    final url = '$_baseUrl/queries/rate';
    print('QueryService: Request URL: $url');

    final requestBody = {
      'queryId': queryId,
      'rating': rating,
      if (review != null) 'review': review,
    };

    print('QueryService: Request body: $requestBody');
    print('QueryService: Auth token present: ${_authToken != null}');

    try {
      print('QueryService: Making POST request...');
      final response = await _dio.post(url, data: requestBody);
      print('QueryService: POST request completed successfully');

      final result = await _handleDioResponse(
        response,
            (json) {
          print('QueryService: Parsing response as QueryModel');
          return QueryModel.fromJson(json as Map<String, dynamic>);
        },
      );

      print('QueryService: rateQuery completed successfully: $result');
      return result;
    } on DioException catch (e) {
      print('QueryService: DioException caught in rateQuery');
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in rateQuery: $errorMsg');
      throw Exception('Failed to rate query: $errorMsg');
    } catch (e) {
      print('QueryService: Unexpected exception in rateQuery: $e');
      throw Exception('Failed to rate query: $e');
    }
  }

  Future<QueryModel> replyToQuery({
    required String queryId,
    required String replyText,
  }) async {
    print('QueryService: replyToQuery - Starting');
    print('QueryService: QueryId: $queryId');
    print('QueryService: ReplyText: $replyText');

    final url = '$_baseUrl/queries/reply';
    print('QueryService: Request URL: $url');

    final requestBody = ReplyQueryRequestModel(queryId: queryId, message: replyText).toJson();
    print('QueryService: Request body: $requestBody');
    print('QueryService: Auth token present: ${_authToken != null}');

    try {
      print('QueryService: Making POST request...');
      final response = await _dio.post(url, data: requestBody);
      print('QueryService: POST request completed successfully');

      final result = await _handleDioResponse(response, (json) {
        print('QueryService: Parsing response as QueryModel');
        return QueryModel.fromJson(json as Map<String, dynamic>);
      });

      print('QueryService: replyToQuery completed successfully: $result');
      return result;
    } on DioException catch (e) {
      print('QueryService: DioException caught in replyToQuery');
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in replyToQuery: $errorMsg');
      throw Exception('Failed to reply to query: $errorMsg');
    } catch (e) {
      print('QueryService: Unexpected exception in replyToQuery: $e');
      throw Exception('Failed to reply to query: $e');
    }
  }

  Future<List<QueryModel>> getMyQueries() async {
    print('QueryService: getMyQueries - Starting');
    final url = '$_baseUrl/queries/my';
    print('QueryService: Request URL: $url');
    print('QueryService: Auth token present: ${_authToken != null}');

    try {
      print('QueryService: Making GET request...');
      final response = await _dio.get(url);
      print('QueryService: GET request completed successfully');

      final result = await _handleDioResponse(
        response,
            (jsonData) {
          print('QueryService: Parsing response data for getMyQueries');
          print('QueryService: JsonData type: ${jsonData.runtimeType}');
          print('QueryService: JsonData content: $jsonData');

          if (jsonData is List) {
            print('QueryService: Response is a list with ${jsonData.length} items');
            final queries = jsonData
                .map((e) {
              print('QueryService: Parsing query item: $e');
              return QueryModel.fromJson(e as Map<String, dynamic>);
            })
                .toList();
            print('QueryService: Successfully parsed ${queries.length} queries');
            return queries;
          } else if (jsonData is Map<String, dynamic>) {
            print('QueryService: Response is a single query object');
            final query = QueryModel.fromJson(jsonData);
            print('QueryService: Successfully parsed single query: $query');
            return [query];
          } else {
            print('QueryService: ERROR - Unexpected response format for queries');
            throw Exception("Unexpected response format for queries.");
          }
        },
      );

      print('QueryService: getMyQueries completed successfully with ${result.length} queries');
      return result;
    } on DioException catch (e) {
      print('QueryService: DioException caught in getMyQueries');
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in getMyQueries: $errorMsg');
      throw Exception('Failed to load queries: $errorMsg');
    } catch (e) {
      print('QueryService: Unexpected exception in getMyQueries: $e');
      throw Exception('Failed to load queries: $e');
    }
  }

  Future<QueryModel> getQueryById(String queryId) async {
    print('QueryService: getQueryById - Starting');
    print('QueryService: QueryId: $queryId');

    final url = '$_baseUrl/queries/$queryId';
    print('QueryService: Request URL: $url');
    print('QueryService: Auth token present: ${_authToken != null}');

    try {
      print('QueryService: Making GET request...');
      final response = await _dio.get(url);
      print('QueryService: GET request completed successfully');

      final result = await _handleDioResponse(response, (json) {
        print('QueryService: Parsing response as QueryModel');
        return QueryModel.fromJson(json as Map<String, dynamic>);
      });

      print('QueryService: getQueryById completed successfully: $result');
      return result;
    } on DioException catch (e) {
      print('QueryService: DioException caught in getQueryById');
      final errorMsg = _getDioErrorMessage(e);
      print('QueryService: Error in getQueryById: $errorMsg');
      throw Exception('Failed to get query by ID: $errorMsg');
    } catch (e) {
      print('QueryService: Unexpected exception in getQueryById: $e');
      throw Exception('Failed to get query by ID: $e');
    }
  }
}
