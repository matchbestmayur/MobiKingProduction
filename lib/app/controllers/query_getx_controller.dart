import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/QueryModel.dart';
import '../services/query_service.dart';
import '../themes/app_theme.dart';

import 'package:mobiking/app/controllers/connectivity_controller.dart';

class QueryGetXController extends GetxController {
  /// Main list of user queries (order-linked and general)
  final RxList<QueryModel> _myQueries = <QueryModel>[].obs;
  RxList<QueryModel> get myQueries => _myQueries; // <--- CRUCIAL: RxList for GetX reactivity

  RxInt get queryCount => _myQueries.length.obs;

  // Loading/error state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxBool _isLoadingReplies = false.obs;
  bool get isLoadingReplies => _isLoadingReplies.value;

  final RxString _errorMessage = RxString('');
  String? get errorMessage => _errorMessage.value.isEmpty ? null : _errorMessage.value;

  // Selection & detail
  final Rx<QueryModel?> _selectedQuery = Rx<QueryModel?>(null);
  QueryModel? get selectedQuery => _selectedQuery.value;

  final Rx<QueryModel?> _currentQuery = Rx<QueryModel?>(null);
  QueryModel? get currentQuery => _currentQuery.value;

  late final TextEditingController _replyInputController;
  TextEditingController get replyInputController => _replyInputController;

  final QueryService _queryService = Get.find<QueryService>();
  final GetStorage _box = GetStorage();
  final RxList<ReplyModel> replies = <ReplyModel>[].obs;

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();
  final StreamController<List<dynamic>> _conversationStreamController =
  StreamController<List<dynamic>>.broadcast();

  Stream<List<dynamic>> get conversationStream => _conversationStreamController.stream;

  Timer? _pollingTimer;
  final Duration _pollingInterval = const Duration(seconds: 3);

  // Typing indicator
  final RxBool _isTyping = false.obs;
  bool get isTyping => _isTyping.value;
  Timer? _typingTimer;

  @override
  void onInit() {
    super.onInit();
    _replyInputController = TextEditingController();
    _setAuthTokenFromStorage();
    _fetchAndLoadMyQueries();

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) _handleConnectionRestored();
    });

    ever(_currentQuery, (QueryModel? query) {
      if (query != null) {
        _startConversationPolling();
        _updateConversationStream(query.replies ?? []);
      } else {
        _stopConversationPolling();
      }
    });

    _replyInputController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_replyInputController.text.trim().isNotEmpty) {
      _startTyping();
    } else {
      _stopTyping();
    }
  }

  void _startTyping() {
    if (!_isTyping.value) _isTyping.value = true;
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping.value) _isTyping.value = false;
    _typingTimer?.cancel();
  }

  void _startConversationPolling() {
    _stopConversationPolling();
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (_currentQuery.value?.id != null) {
        _pollConversationUpdates();
      }
    });
  }

  void _stopConversationPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollConversationUpdates() async {
    if (_currentQuery.value?.id == null) return;
    try {
      final updatedQuery = await _queryService.getQueryById(_currentQuery.value!.id!);
      final currentRepliesCount = _currentQuery.value?.replies?.length ?? 0;
      final newRepliesCount = updatedQuery.replies?.length ?? 0;
      if (newRepliesCount > currentRepliesCount) {
        _currentQuery.value = updatedQuery;
        _updateQueryInList(updatedQuery);
        _updateConversationStream(updatedQuery.replies ?? []);
        _showNewMessageNotification();
      }
    } catch (e) {
      print('QueryGetXController: Error polling conversation: $e');
    }
  }

  void _updateConversationStream(List<dynamic> replies) {
    if (!_conversationStreamController.isClosed) {
      _conversationStreamController.add(replies);
    }
  }

  void _showNewMessageNotification() {
    _showModernSnackbar(
      title: 'New Reply',
      message: 'You have received a new reply to your query.',
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _handleConnectionRestored() async {
    if (!_isLoading.value) {
      await _fetchAndLoadMyQueries();
      if (_currentQuery.value != null) {
        _startConversationPolling();
      }
    }
  }

  @override
  void onClose() {
    _replyInputController.removeListener(_onTextChanged);
    _replyInputController.dispose();
    _stopConversationPolling();
    _conversationStreamController.close();
    _typingTimer?.cancel();
    super.onClose();
  }

  void _setAuthTokenFromStorage() {
    final String? accessToken = _box.read('accessToken');
    if (accessToken != null && accessToken.isNotEmpty) {
      _queryService.setAuthToken(accessToken);
    }
  }

  void setAuthToken(String token) {
    _queryService.setAuthToken(token);
    _box.write('accessToken', token);
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
      _myQueries.insert(0, updatedQuery);
      _myQueries.refresh();
    }
    if (_currentQuery.value?.id == updatedQuery.id) {
      _currentQuery.value = updatedQuery;
    }
    if (_selectedQuery.value?.id == updatedQuery.id) {
      _selectedQuery.value = updatedQuery;
    }
  }

  /// Fetch all queries from backend (called on startup & when refreshing)
  Future<void> _fetchAndLoadMyQueries() async {
    if (_isLoading.value) return;
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final queries = await _queryService.getMyQueries();
      _myQueries.value = queries;
      _myQueries.refresh();
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error fetching queries.');
      _errorMessage.value = userFriendlyMessage;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshMyQueries() async {
    await _fetchAndLoadMyQueries();
  }

  Future<void> fetchQueryByOrderId(String orderId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      await _fetchAndLoadMyQueries();
      // Use .toString() to avoid type mismatch bugs!
      final queryForOrder = _myQueries.where((query) => query.orderId?.toString() == orderId?.toString()).toList();
      if (queryForOrder.isNotEmpty) {
        queryForOrder.sort((a, b) => (b.raisedAt ?? DateTime.now()).compareTo(a.raisedAt ?? DateTime.now()));
        _currentQuery.value = queryForOrder.first;
        await refreshCurrentQuery();
      } else {
        _currentQuery.value = null;
      }
    } catch (e) {
      _errorMessage.value = _getFriendlyErrorMessage(e, 'Error fetching query for order.');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> fetchQueryById(String queryId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      final query = await _queryService.getQueryById(queryId);
      _currentQuery.value = query;
      _updateQueryInList(query);
      _updateConversationStream(query.replies ?? []);
    } catch (e) {
      _errorMessage.value = _getFriendlyErrorMessage(e, 'Error fetching query details.');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshCurrentQuery() async {
    if (_currentQuery.value?.id == null) return;
    try {
      _isLoadingReplies.value = true;
      final refreshedQuery = await _queryService.getQueryById(_currentQuery.value!.id!);
      _currentQuery.value = refreshedQuery;
      _updateQueryInList(refreshedQuery);
      _updateConversationStream(refreshedQuery.replies ?? []);
    } catch (e) {
      _errorMessage.value = _getFriendlyErrorMessage(e, 'Error refreshing query.');
    } finally {
      _isLoadingReplies.value = false;
    }
  }

  void setCurrentQuery(QueryModel query) {
    _currentQuery.value = query;
    _updateConversationStream(query.replies ?? []);
  }

  void clearCurrentQuery() {
    _currentQuery.value = null;
    _stopConversationPolling();
  }

  /// --- THIS METHOD IS CRUCIAL ---
  /// Raise a query, update RxList immediately *and* refresh from backend for 100% safety
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
      _myQueries.refresh();
      // Always refresh from backend; this is most robust in production (handles server-side changes)
      await refreshMyQueries();
      if (orderId != null) {
        _currentQuery.value = newQuery;
        _updateConversationStream(newQuery.replies ?? []);
      }
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error raising query.');
      _errorMessage.value = userFriendlyMessage;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Reply logic (for completeness; your code)
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
    _stopTyping();
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final updatedQuery = await _queryService.replyToQuery(
        queryId: queryId,
        replyText: replyText,
      );
      _updateQueryInList(updatedQuery);
      _replyInputController.clear();
      _updateConversationStream(updatedQuery.replies ?? []);
      if (_currentQuery.value?.id == queryId) {
        await Future.delayed(const Duration(milliseconds: 500));
        await refreshCurrentQuery();
      }
      _showModernSnackbar(
        title: 'Success',
        message: 'Reply sent successfully!',
        isSuccess: true,
      );
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error replying to query.');
      _errorMessage.value = userFriendlyMessage;
      _showModernSnackbar(
        title: 'Error',
        message: userFriendlyMessage,
        isSuccess: false,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  QueryModel? getQueryByOrderId(String orderId) {
    // Defensive, use .toString() in comparison for all cases!
    return _myQueries.firstWhereOrNull((query) => query.orderId?.toString() == orderId?.toString());
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
      case 'pending':
        return AppColors.info;
      case 'pending_reply':
      case 'in_progress':
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
