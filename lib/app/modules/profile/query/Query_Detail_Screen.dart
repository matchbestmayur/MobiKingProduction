import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobiking/app/controllers/query_getx_controller.dart';
import 'package:mobiking/app/themes/app_theme.dart';

import '../../../data/QueryModel.dart';
import '../../../data/order_model.dart';

class QueryDetailScreen extends StatefulWidget {
  final QueryModel? query;
  final OrderModel? order;
  final String? orderId;

  const QueryDetailScreen({
    Key? key,
    this.query,
    this.order,
    this.orderId,
  }) : super(key: key);

  @override
  State<QueryDetailScreen> createState() => _QueryDetailScreenState();
}

class _QueryDetailScreenState extends State<QueryDetailScreen> with TickerProviderStateMixin {
  final QueryGetXController controller = Get.find<QueryGetXController>();
  bool _isTextFieldFocused = false;
  final FocusNode _textFieldFocusNode = FocusNode();

  // ✅ Add ScrollController for conversation
  final ScrollController _scrollController = ScrollController();

  // ✅ Add animation controllers for message animations
  late AnimationController _messageAnimationController;
  late Animation<double> _messageAnimation;

  // ✅ Add typing animation controller
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    print('QueryDetailScreen: initState called');
    print('QueryDetailScreen: Widget query: ${widget.query?.id}');
    print('QueryDetailScreen: Widget orderId: ${widget.orderId}');
    print('QueryDetailScreen: Widget order: ${widget.order?.id}');

    _initializeAnimations();
    _initializeData();
    _setupFocusListener();
  }

  void _initializeAnimations() {
    // Message animation
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _messageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeInOut,
    ));

    // Typing animation
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _messageAnimationController.forward();
  }

  void _initializeData() async {
    print('QueryDetailScreen: _initializeData starting');

    // If we have a query, fetch its details and set as current
    if (widget.query?.id != null) {
      print('QueryDetailScreen: Setting and fetching query by ID: ${widget.query!.id}');
      controller.setCurrentQuery(widget.query!);
      await controller.fetchQueryById(widget.query!.id!);
    }
    // If we have an orderId but no query, fetch query for this order
    else if (widget.orderId != null) {
      print('QueryDetailScreen: Fetching query by order ID: ${widget.orderId}');
      await controller.fetchQueryByOrderId(widget.orderId!);
    }
    // If we have an order but no query, fetch query for this order
    else if (widget.order?.id != null) {
      print('QueryDetailScreen: Fetching query by order ID from order: ${widget.order!.id}');
      await controller.fetchQueryByOrderId(widget.order!.id!);
    }
  }

  void _setupFocusListener() {
    _textFieldFocusNode.addListener(() {
      if (_textFieldFocusNode.hasFocus && !_isTextFieldFocused) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {
              _isTextFieldFocused = true;
            });
          }
        });
      } else if (!_textFieldFocusNode.hasFocus && _isTextFieldFocused) {
        setState(() {
          _isTextFieldFocused = false;
        });
      }
    });
  }

  // ✅ Add method to scroll to bottom with animation
  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _messageAnimationController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          'Query Details',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        foregroundColor: AppColors.white,
        actions: [
          // ✅ Add connection status indicator
          Obx(() {
            final isLoading = controller.isLoadingReplies;
            return isLoading
                ? Container(
              margin: const EdgeInsets.only(right: 8),
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                print('QueryDetailScreen: Manual refresh triggered');
                await controller.refreshCurrentQuery();
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        // Use reactive current query
        final currentQuery = controller.currentQuery;
        final isLoading = controller.isLoading;

        if (isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading query details...'),
              ],
            ),
          );
        }

        // Show message if no query is found
        if (currentQuery == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 64,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Query Found',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No query exists for this order yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _showCreateQueryDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Create Query'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Scrollable content section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Order Information Card
                    _buildOrderInfoCard(widget.order, textTheme),

                    // Query Details Card - use currentQuery from controller
                    _buildQueryDetailsCard(currentQuery, textTheme),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ✅ Real-time Conversation Section with StreamBuilder
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Conversation header with live status
                  _buildConversationHeader(textTheme),

                  // ✅ StreamBuilder for real-time conversation
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightGreyBackground, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: StreamBuilder<List<dynamic>>(
                        stream: controller.conversationStream,
                        initialData: currentQuery.replies ?? [],
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting &&
                              (snapshot.data?.isEmpty ?? true)) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final replies = snapshot.data ?? [];
                          return _buildConversationList(replies, textTheme);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fixed input at bottom with typing indicator
            if (currentQuery.status != 'resolved')
              _buildMessageInputWithTyping(textTheme),
          ],
        );
      }),
    );
  }

  // ✅ Enhanced conversation header with live status
  Widget _buildConversationHeader(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline,
              color: AppColors.primaryPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            'Conversation',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          // ✅ Live status indicator
          Obx(() {
            final isLoadingReplies = controller.isLoadingReplies;
            final currentQuery = controller.currentQuery;

            if (isLoadingReplies) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Syncing...',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          Obx(() {
            final currentQuery = controller.currentQuery;
            if (currentQuery?.status != 'resolved') {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // Order Information Card (same as before)
  Widget _buildOrderInfoCard(OrderModel? order, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple,
            AppColors.primaryPurple.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_bag, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Query related to this order',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOrderInfoItem(
                    'Order ID',
                    widget.orderId ?? order?.id ?? 'N/A',
                    textTheme,
                  ),
                ),
                Expanded(
                  child: _buildOrderInfoItem(
                    'Amount',
                    '₹${order?.orderAmount?.toStringAsFixed(0) ?? 'N/A'}',
                    textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildOrderInfoItem(
                    'Date',
                    order?.createdAt != null
                        ? DateFormat('MMM d, yyyy').format(order!.createdAt!)
                        : 'N/A',
                    textTheme,
                  ),
                ),
                Expanded(
                  child: _buildOrderInfoItem(
                    'Status',
                    order?.status?.capitalizeFirst ?? 'N/A',
                    textTheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoItem(String label, String value, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Query Details Card (same as before)
  Widget _buildQueryDetailsCard(QueryModel? query, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreyBackground, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    query?.title ?? 'Query Title',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(query?.status ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    query?.status?.capitalizeFirst ?? 'Pending',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(query?.status ?? ''),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              query?.message ?? 'No message available.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Raised ${DateFormat('MMM d, yyyy').format(query?.raisedAt ?? DateTime.now())}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (query?.status == 'resolved' && query?.resolvedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Resolved ${DateFormat('MMM d').format(query!.resolvedAt!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Enhanced conversation list with animations
  Widget _buildConversationList(List<dynamic> replies, TextTheme textTheme) {
    if (replies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline,
                  size: 32, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation by sending a message',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort replies by timestamp to ensure proper chronological order
    final sortedReplies = List.from(replies);
    sortedReplies.sort((a, b) {
      final dateA = a.timestamp ?? a.createdAt ?? DateTime.now();
      final dateB = b.timestamp ?? b.createdAt ?? DateTime.now();
      return dateA.compareTo(dateB); // Oldest first
    });

    print('QueryDetailScreen: Displaying ${sortedReplies.length} messages in chronological order');

    // Auto-scroll to bottom after building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Column(
      children: [
        // Message list
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: sortedReplies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final reply = sortedReplies[index];
              final isUser = !reply.isAdmin;

              return AnimatedBuilder(
                animation: _messageAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * _messageAnimation.value),
                    child: Opacity(
                      opacity: _messageAnimation.value,
                      child: _buildMessageBubble(reply, isUser, textTheme),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // ✅ Typing indicator
        Obx(() {
          final isTyping = controller.isTyping;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isTyping ? 50 : 0,
            child: isTyping ? _buildTypingIndicator(textTheme) : null,
          );
        }),
      ],
    );
  }

  // ✅ Build message bubble
  Widget _buildMessageBubble(dynamic reply, bool isUser, TextTheme textTheme) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryPurple : AppColors.neutralBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Support Team',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                reply.replyText ?? reply.message ?? 'No message',
                style: textTheme.bodyMedium?.copyWith(
                  color: isUser ? AppColors.white : AppColors.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM d, hh:mm a').format(
                      reply.timestamp ?? reply.createdAt ?? DateTime.now(),
                    ),
                    style: textTheme.labelSmall?.copyWith(
                      color: isUser
                          ? AppColors.white.withOpacity(0.7)
                          : AppColors.textLight,
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.white.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Build typing indicator
  Widget _buildTypingIndicator(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutralBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Support is typing',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _typingAnimationController,
                      builder: (context, child) {
                        return Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withOpacity(
                              0.3 + (0.7 * ((_typingAnimationController.value + index * 0.3) % 1.0)),
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Enhanced message input with real-time typing detection
  Widget _buildMessageInputWithTyping(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightGreyBackground, width: 1),
        ),
        boxShadow: _isTextFieldFocused ? [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ] : null,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            /*Container(
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.attach_file, color: AppColors.textLight),
                onPressed: () => _showAttachmentOptions(),
              ),
            ),*/
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neutralBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: _isTextFieldFocused ? Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    width: 1,
                  ) : null,
                ),
                child: TextField(
                  controller: controller.replyInputController,
                  focusNode: _textFieldFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              final isLoading = controller.isLoading;
              return Container(
                decoration: BoxDecoration(
                  color: isLoading ? AppColors.textLight : AppColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                      : Icon(Icons.send, color: AppColors.white),
                  onPressed: isLoading ? null : () => _sendMessage(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'open':
        return AppColors.danger;
      case 'in_progress':
      case 'pending_reply':
        return AppColors.primaryPurple;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textLight;
      default:
        return AppColors.danger;
    }
  }

  // ✅ Enhanced _sendMessage with animation
  void _sendMessage() {
    print('QueryDetailScreen: _sendMessage called');
    final currentQuery = controller.currentQuery;

    if (controller.replyInputController.text.trim().isNotEmpty && currentQuery?.id != null) {
      print('QueryDetailScreen: Sending reply to query: ${currentQuery!.id}');

      // Start typing animation
      _typingAnimationController.repeat();

      controller.replyToQuery(
        queryId: currentQuery.id!,
        replyText: controller.replyInputController.text.trim(),
      );

      // Remove focus after sending message
      _textFieldFocusNode.unfocus();

      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 500), () {
        _scrollToBottom();
        _typingAnimationController.stop();
      });

    } else {
      print('QueryDetailScreen: Cannot send message - text empty or no current query');
      if (currentQuery?.id == null) {
        /*Get.snackbar(
          'Error',
          'No active query found. Please refresh the page.',
          backgroundColor: AppColors.danger,
          colorText: AppColors.white,
        );*/
      }
    }
  }

  void _showCreateQueryDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create Query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Query Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty &&
                  messageController.text.trim().isNotEmpty) {
                Get.back();
                await controller.raiseQuery(
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                  orderId: widget.orderId ?? widget.order?.id,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Attachment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.camera_alt, 'Camera', () {}),
                _buildAttachmentOption(Icons.image, 'Gallery', () {}),
                _buildAttachmentOption(Icons.insert_drive_file, 'Document', () {}),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neutralBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryPurple, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
