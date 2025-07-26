import 'dart:async';
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

  // ADD: Loading state for replies specifically
  final RxBool _isLoadingReplies = false.obs;
  bool get isLoadingReplies => _isLoadingReplies.value;

  final RxString _errorMessage = RxString('');
  String? get errorMessage => _errorMessage.value.isEmpty ? null : _errorMessage.value;

  final Rx<QueryModel?> _selectedQuery = Rx<QueryModel?>(null);
  QueryModel? get selectedQuery => _selectedQuery.value;

  // ADD: Current query for detail screen
  final Rx<QueryModel?> _currentQuery = Rx<QueryModel?>(null);
  QueryModel? get currentQuery => _currentQuery.value;

  late final TextEditingController _replyInputController;
  TextEditingController get replyInputController => _replyInputController;

  final QueryService _queryService = Get.find<QueryService>();
  final GetStorage _box = GetStorage();
  final RxList<ReplyModel> replies = <ReplyModel>[].obs;

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();

  // ✅ Add Stream for real-time conversation updates
  final StreamController<List<dynamic>> _conversationStreamController =
  StreamController<List<dynamic>>.broadcast();

  Stream<List<dynamic>> get conversationStream => _conversationStreamController.stream;

  // ✅ Add timer for polling updates
  Timer? _pollingTimer;
  final Duration _pollingInterval = const Duration(seconds: 3);

  // ✅ Add typing indicator
  final RxBool _isTyping = false.obs;
  bool get isTyping => _isTyping.value;
  Timer? _typingTimer;

  @override
  void onInit() {
    super.onInit();
    print('QueryGetXController: onInit called');
    _replyInputController = TextEditingController();
    _setAuthTokenFromStorage();
    _fetchAndLoadMyQueries();

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });

    // ✅ Start conversation polling when current query changes
    ever(_currentQuery, (QueryModel? query) {
      if (query != null) {
        _startConversationPolling();
        _updateConversationStream(query.replies ?? []);
      } else {
        _stopConversationPolling();
      }
    });

    // ✅ Add typing indicator listener
    _replyInputController.addListener(_onTextChanged);
  }

  // ✅ Handle text changes for typing indicator
  void _onTextChanged() {
    if (_replyInputController.text.trim().isNotEmpty) {
      _startTyping();
    } else {
      _stopTyping();
    }
  }

  // ✅ Start typing indicator
  void _startTyping() {
    if (!_isTyping.value) {
      _isTyping.value = true;
      print('QueryGetXController: User started typing');
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  // ✅ Stop typing indicator
  void _stopTyping() {
    if (_isTyping.value) {
      _isTyping.value = false;
      print('QueryGetXController: User stopped typing');
    }
    _typingTimer?.cancel();
  }

  // ✅ Start polling for conversation updates
  void _startConversationPolling() {
    print('QueryGetXController: Starting conversation polling');
    _stopConversationPolling(); // Stop any existing timer

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (_currentQuery.value?.id != null) {
        _pollConversationUpdates();
      }
    });
  }

  // ✅ Stop polling
  void _stopConversationPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('QueryGetXController: Stopped conversation polling');
  }

  // ✅ Poll for conversation updates
  Future<void> _pollConversationUpdates() async {
    if (_currentQuery.value?.id == null) return;

    try {
      print('QueryGetXController: Polling conversation updates for query: ${_currentQuery.value!.id}');
      final updatedQuery = await _queryService.getQueryById(_currentQuery.value!.id!);

      // Check if there are new replies
      final currentRepliesCount = _currentQuery.value?.replies?.length ?? 0;
      final newRepliesCount = updatedQuery.replies?.length ?? 0;

      if (newRepliesCount > currentRepliesCount) {
        print('QueryGetXController: New replies detected: $currentRepliesCount -> $newRepliesCount');
        _currentQuery.value = updatedQuery;
        _updateQueryInList(updatedQuery);
        _updateConversationStream(updatedQuery.replies ?? []);

        // Show notification for new messages
        _showNewMessageNotification();
      }

    } catch (e) {
      print('QueryGetXController: Error polling conversation: $e');
    }
  }

  // ✅ Update conversation stream
  void _updateConversationStream(List<dynamic> replies) {
    print('QueryGetXController: Updating conversation stream with ${replies.length} replies');
    if (!_conversationStreamController.isClosed) {
      _conversationStreamController.add(replies);
    }
  }

  // ✅ Show new message notification
  void _showNewMessageNotification() {
    _showModernSnackbar(
      title: 'New Reply',
      message: 'You have received a new reply to your query.',
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _handleConnectionRestored() async {
    print('QueryGetXController: Internet connection restored. Re-fetching queries...');
    if (!_isLoading.value) {
      await _fetchAndLoadMyQueries();
      // Restart polling if we have a current query
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
      print('QueryGetXController: Access token loaded and set for QueryService.');
    } else {
      print('QueryGetXController: No access token found in GetStorage. Authenticated calls might fail.');
    }
  }

  // ADD: Set auth token method (for external use)
  void setAuthToken(String token) {
    print('QueryGetXController: Setting auth token externally');
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
    print('QueryGetXController: _updateQueryInList - Query ID: ${updatedQuery.id}');
    final int index = _myQueries.indexWhere((q) => q.id == updatedQuery.id);
    if (index != -1) {
      _myQueries[index] = updatedQuery;
      _myQueries.refresh();
      print('QueryGetXController: Updated query at index $index');
    } else {
      _myQueries.add(updatedQuery);
      print('QueryGetXController: Added new query to list. ID: ${updatedQuery.id}');
    }

    // ADD: Update current query if it matches
    if (_currentQuery.value?.id == updatedQuery.id) {
      _currentQuery.value = updatedQuery;
      print('QueryGetXController: Updated current query');
    }

    if (_selectedQuery.value?.id == updatedQuery.id) {
      _selectedQuery.value = updatedQuery;
      print('QueryGetXController: Updated selected query');
    }
  }

  Future<void> _fetchAndLoadMyQueries() async {
    if (_isLoading.value) return;
    print('QueryGetXController: _fetchAndLoadMyQueries starting');
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final queries = await _queryService.getMyQueries();
      _myQueries.value = queries;
      print('QueryGetXController: Fetched queries: ${queries.length} items.');
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error fetching queries.');
      _errorMessage.value = userFriendlyMessage;
      print('QueryGetXController: Error fetching queries: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshMyQueries() async {
    print('QueryGetXController: refreshMyQueries called');
    await _fetchAndLoadMyQueries();
  }

  // ADD: Fetch query by order ID
  Future<void> fetchQueryByOrderId(String orderId) async {
    print('QueryGetXController: fetchQueryByOrderId - OrderId: $orderId');

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // First ensure we have all queries loaded
      await _fetchAndLoadMyQueries();

      // Find query by order ID
      final queryForOrder = _myQueries.where((query) => query.orderId == orderId).toList();
      print('QueryGetXController: Found ${queryForOrder.length} queries for order $orderId');

      if (queryForOrder.isNotEmpty) {
        // Get the most recent query for this order
        queryForOrder.sort((a, b) => (b.raisedAt ?? DateTime.now()).compareTo(a.raisedAt ?? DateTime.now()));
        _currentQuery.value = queryForOrder.first;
        print('QueryGetXController: Set current query: ${_currentQuery.value?.id}');

        // Fetch detailed query info to get latest replies
        await refreshCurrentQuery();
      } else {
        _currentQuery.value = null;
        print('QueryGetXController: No query found for order $orderId');
      }

    } catch (e) {
      print('QueryGetXController: Error in fetchQueryByOrderId: $e');
      _errorMessage.value = _getFriendlyErrorMessage(e, 'Error fetching query for order.');
    } finally {
      _isLoading.value = false;
    }
  }

  // ADD: Fetch query by query ID
  Future<void> fetchQueryById(String queryId) async {
    print('QueryGetXController: fetchQueryById - QueryId: $queryId');

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final query = await _queryService.getQueryById(queryId);
      _currentQuery.value = query;
      print('QueryGetXController: Fetched query details: ${query.id}');
      print('QueryGetXController: Query has ${query.replies?.length ?? 0} replies');

      // Also update in the list if it exists
      _updateQueryInList(query);

      // Update conversation stream
      _updateConversationStream(query.replies ?? []);

    } catch (e) {
      print('QueryGetXController: Error in fetchQueryById: $e');
      _errorMessage.value = _getFriendlyErrorMessage(e, 'Error fetching query details.');
    } finally {
      _isLoading.value = false;
    }
  }

  // ADD: Refresh current query to get latest replies
  Future<void> refreshCurrentQuery() async {
    print('QueryGetXController: refreshCurrentQuery');

    if (_currentQuery.value?.id == null) {
      print('QueryGetXController: No current query to refresh');
      return;
    }

    try {
      _isLoadingReplies.value = true;
      final refreshedQuery = await _queryService.getQueryById(_currentQuery.value!.id!);
      _currentQuery.value = refreshedQuery;
      print('QueryGetXController: Refreshed query with ${refreshedQuery.replies?.length ?? 0} replies');

      // Update in the main list too
      _updateQueryInList(refreshedQuery);

      // Update conversation stream
      _updateConversationStream(refreshedQuery.replies ?? []);

    } catch (e) {
      print('QueryGetXController: Error refreshing query: $e');
      _errorMessage.value = _getFriendlyErrorMessage(e, 'Error refreshing query.');
    } finally {
      _isLoadingReplies.value = false;
    }
  }

  // ADD: Set current query (for navigation)
  void setCurrentQuery(QueryModel query) {
    print('QueryGetXController: setCurrentQuery - Query ID: ${query.id}');
    _currentQuery.value = query;
    _updateConversationStream(query.replies ?? []);
  }

  // ADD: Clear current query
  void clearCurrentQuery() {
    print('QueryGetXController: clearCurrentQuery');
    _currentQuery.value = null;
    _stopConversationPolling();
  }

  Future<void> raiseQuery({
    required String title,
    required String message,
    String? orderId,
  }) async {
    print('QueryGetXController: raiseQuery - Title: $title, OrderId: $orderId');
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final newQuery = await _queryService.raiseQuery(
        title: title,
        message: message,
        orderId: orderId,
      );
      _myQueries.insert(0, newQuery);
      // Set as current query if we're raising for specific order
      if (orderId != null) {
        _currentQuery.value = newQuery;
        _updateConversationStream(newQuery.replies ?? []);
      }
      print('QueryGetXController: New query raised: ${newQuery.id}');
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error raising query.');
      _errorMessage.value = userFriendlyMessage;
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
    print('QueryGetXController: rateQuery - QueryId: $queryId, Rating: $rating');
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final updatedQuery = await _queryService.rateQuery(
        queryId: queryId,
        rating: rating,
        review: review,
      );
      _updateQueryInList(updatedQuery);
      print('QueryGetXController: Query rated: ${updatedQuery.id}');
    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error rating query.');
      _errorMessage.value = userFriendlyMessage;
      print('QueryGetXController: Error rating query: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> replyToQuery({
    required String queryId,
    required String replyText,
  }) async {
    print('QueryGetXController: replyToQuery - QueryId: $queryId, Reply: $replyText');

    if (replyText.trim().isEmpty) {
      print('QueryGetXController: Reply text is empty, returning');
      _showModernSnackbar(
        title: 'Input Error',
        message: 'Reply message cannot be empty.',
        isSuccess: false,
      );
      return;
    }

    // Stop typing indicator
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

      // Update conversation stream immediately
      _updateConversationStream(updatedQuery.replies ?? []);

      // ADD: Refresh current query to get the very latest state
      if (_currentQuery.value?.id == queryId) {
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay
        await refreshCurrentQuery();
      }

      print('QueryGetXController: Replied to query: ${updatedQuery.id}');
      print('QueryGetXController: Updated query has ${updatedQuery.replies?.length ?? 0} replies');

      _showModernSnackbar(
        title: 'Success',
        message: 'Reply sent successfully!',
        isSuccess: true,
      );

    } catch (e) {
      final userFriendlyMessage = _getFriendlyErrorMessage(e, 'Error replying to query.');
      _errorMessage.value = userFriendlyMessage;
      print('QueryGetXController: Error replying to query: $e');

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
    print('QueryGetXController: getQueryByOrderId - OrderId: $orderId');
    final query = _myQueries.firstWhereOrNull((query) => query.orderId == orderId);
    print('QueryGetXController: Found query: ${query?.id}');
    return query;
  }

  void selectQuery(QueryModel query) {
    print('QueryGetXController: selectQuery - Query ID: ${query.id}');
    _selectedQuery.value = query;
  }

  void clearSelectedQuery() {
    print('QueryGetXController: clearSelectedQuery');
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
