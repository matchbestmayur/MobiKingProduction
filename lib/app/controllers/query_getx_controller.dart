import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/QueryModel.dart';
import '../services/query_service.dart';
import '../themes/app_theme.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';

class QueryGetXController extends GetxController {
  final RxList<QueryModel> _myQueries = <QueryModel>[].obs;
  List<QueryModel> get myQueries => _myQueries.value;

  // NEW: Expose query count reactively
  RxInt get queryCount => _myQueries.length.obs;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxString _errorMessage = RxString('');
  String? get errorMessage => _errorMessage.value.isEmpty ? null : _errorMessage.value;

  final Rx<QueryModel?> _selectedQuery = Rx<QueryModel?>(null);
  QueryModel? get selectedQuery => _selectedQuery.value;

  late final TextEditingController _replyInputController;
  TextEditingController get replyInputController => _replyInputController;

  final QueryService _queryService = Get.find<QueryService>();
  final GetStorage _box = GetStorage();
  final RxList<ReplyModel> replies = <ReplyModel>[].obs;

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();

  @override
  void onInit() {
    super.onInit();
    _replyInputController = TextEditingController();
    _setAuthTokenFromStorage();
    _fetchAndLoadMyQueries();

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  Future<void> _handleConnectionRestored() async {
    print('QueryGetXController: Internet connection restored. Re-fetching queries...');
    if (!_isLoading.value) {
      await _fetchAndLoadMyQueries();
    }
  }

  @override
  void onClose() {
    _replyInputController.dispose();
    super.onClose();
  }

  void _setAuthTokenFromStorage() {
    final String? accessToken = _box.read('accessToken');
    if (accessToken != null && accessToken.isNotEmpty) {
      _queryService.setAuthToken(accessToken);
      print('QueryGetXController: Access token loaded and set for QueryService.');
    } else {
      print('QueryGetXController: No access token found in GetStorage. Authenticated calls might fail.');
      _showModernSnackbar(
        title: 'Authentication Missing',
        message: 'No access token found. Please log in.',
        isSuccess: false,
      );
    }
  }

  String _getFriendlyErrorMessage(dynamic e, String defaultMessage) {
    String message = defaultMessage;
    if (e is Exception) {
      final String errorString = e.toString();
      final regex = RegExp(r'Exception: Failed to (?:raise|load|rate|reply to|get|mark) query: (.*)');
      final match = regex.firstMatch(errorString);
      if (match != null && match.groupCount >= 1) {
        message = match.group(1)!;
      } else {
        message = errorString;
      }
    } else {
      message = e.toString();
    }
    return message.trim().isEmpty ? defaultMessage : message;
  }

  void _updateQueryInList(QueryModel updatedQuery) {
    final int index = _myQueries.indexWhere((q) => q.id == updatedQuery.id);
    if (index != -1) {
      _myQueries[index] = updatedQuery;
      _myQueries.refresh();
    } else {
      _myQueries.add(updatedQuery);
      print('Warning: Updated query not found in list, added instead. ID: ${updatedQuery.id}');
    }
    if (_selectedQuery.value?.id == updatedQuery.id) {
      _selectedQuery.value = updatedQuery;
    }
  }

  Future<void> _fetchAndLoadMyQueries() async {
    if (_isLoading.value) return;
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final queries = await _queryService.getMyQueries();
      _myQueries.value = queries;
      _showModernSnackbar(
        title: 'Success',
        message: 'Queries fetched successfully!',
        isSuccess: true,
      );
      print('QueryGetXController: Fetched queries: ${queries.length} items.');
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error fetching queries.');
      _errorMessage.value = userFriendlyMessage;
      _showModernSnackbar(
        title: 'Error',
        message: userFriendlyMessage,
        isSuccess: false,
      );
      print('QueryGetXController: Error fetching queries: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshMyQueries() async {
    await _fetchAndLoadMyQueries();
  }

  Future<void> raiseQuery({
    required String title,
    required String message,
    String? orderId,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final newQuery = await _queryService.raiseQuery(
        title: title,
        message: message,
        orderId: orderId,
      );
      _myQueries.insert(0, newQuery);
      _showModernSnackbar(
        title: 'Success',
        message: 'Query raised successfully! ID: ${newQuery.id}',
        isSuccess: true,
      );
      print('QueryGetXController: New query raised: ${newQuery.toJson()}');
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error raising query.');
      _errorMessage.value = userFriendlyMessage;
      _showModernSnackbar(
        title: 'Error',
        message: userFriendlyMessage,
        isSuccess: false,
      );
      print('QueryGetXController: Error raising query: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> rateQuery({
    required String queryId,
    required int rating,
    String? review,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final updatedQuery = await _queryService.rateQuery(
        queryId: queryId,
        rating: rating,
        review: review,
      );
      _updateQueryInList(updatedQuery);
      _showModernSnackbar(
        title: 'Success',
        message: 'Query rated successfully! ID: ${updatedQuery.id}',
        isSuccess: true,
      );
      print('QueryGetXController: Query rated: ${updatedQuery.toJson()}');
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error rating query.');
      _errorMessage.value = userFriendlyMessage;
      _showModernSnackbar(
        title: 'Error',
        message: userFriendlyMessage,
        isSuccess: false,
      );
      print('QueryGetXController: Error rating query: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> replyToQuery({
    required String queryId,
    required String replyText,
  }) async {
    if (replyText.trim().isEmpty) {
      _showModernSnackbar(
        title: 'Input Error',
        message: 'Reply message cannot be empty.',
        isSuccess: false,
      );
      return;
    }
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final updatedQuery = await _queryService.replyToQuery(
        queryId: queryId,
        replyText: replyText,
      );
      _updateQueryInList(updatedQuery);
      _replyInputController.clear();
      _showModernSnackbar(
        title: 'Success',
        message: 'Replied to query successfully! ID: ${updatedQuery.id}',
        isSuccess: true,
      );
      print('QueryGetXController: Replied to query: ${updatedQuery.toJson()}');
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error replying to query.');
      _errorMessage.value = userFriendlyMessage;
      _showModernSnackbar(
        title: 'Error',
        message: userFriendlyMessage,
        isSuccess: false,
      );
      print('QueryGetXController: Error replying to query: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  QueryModel? getQueryByOrderId(String orderId) {
    return _myQueries.firstWhereOrNull((query) => query.orderId == orderId);
  }

  void selectQuery(QueryModel query) {
    _selectedQuery.value = query;
  }

  void clearSelectedQuery() {
    _selectedQuery.value = null;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.info;
      case 'pending_reply':
        return AppColors.accentOrange;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textLight;
      default:
        return AppColors.textLight;
    }
  }

  void _showModernSnackbar({
    required String title,
    required String message,
    required bool isSuccess,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor = isSuccess ? AppColors.success : AppColors.danger;
    IconData icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
    Get.rawSnackbar(
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Get.textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
        ],
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 12,
      animationDuration: const Duration(milliseconds: 300),
      duration: duration,
    );
  }
}