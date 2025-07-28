// lib/screens/queries_screen.dart
import 'dart:ui'; // Make sure this is imported

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/query_getx_controller.dart'; // Corrected import to QueryGetXController
import '../../../data/QueryModel.dart'; // Use QueryModel from your manual JSON models
import '../../../themes/app_theme.dart'; // Import your AppColors and AppTheme
import 'AboutUsDialog.dart'; // Assuming this exists
import 'FaqDialog.dart';     // Assuming this exists

import 'Raise_query.dart';
import 'query_detail_screen.dart'; // <--- Import the QueryDetailScreen

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  final QueryGetXController queryController = Get.put(QueryGetXController());
  final TextEditingController _quickQueryInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ Initialize queries when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queryController.myQueries;
    });
  }

  @override
  void dispose() {
    _quickQueryInputController.dispose();
    super.dispose();
  }

  void _showRaiseQueryDialog() {
    Get.dialog(
      const RaiseQueryDialog(),
    );
  }

  // ✅ Enhanced quick query submission
  void _handleQuickQuery() async {
    final queryText = _quickQueryInputController.text.trim();

    if (queryText.isEmpty) {
      Get.snackbar(
        'Empty Query',
        'Please enter a question before sending',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      // Create a quick query
      await queryController.raiseQuery(
        title: 'Quick Question',
        message: queryText,
        orderId: null, // Quick queries don't need order ID
      );

      _quickQueryInputController.clear();

      Get.snackbar(
        'Query Submitted',
        'Your question has been sent to support',
        backgroundColor: AppColors.success,
        colorText: AppColors.white,
        snackPosition: SnackPosition.TOP,
      );

      // Navigate to the newly created query detail
      final latestQuery = queryController.myQueries.isNotEmpty
          ? queryController.myQueries.first
          : null;

      if (latestQuery != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToQueryDetail(latestQuery);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit query. Please try again.',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ✅ Enhanced navigation method
  void _navigateToQueryDetail(QueryModel query) {
    queryController.selectQuery(query);
    Get.to(
          () => QueryDetailScreen(query: query),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      // ✅ Add floating action button for raising new query
    /*  floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRaiseQueryDialog,
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        icon: Icon(Icons.add),
        label: Text('Raise Query'),
      ),*/
      body: CustomScrollView(
        slivers: [
          // Top Section: 'Talk with Support' and Quick Input - Enhanced for Blinkit feel
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: AppColors.neutralBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.15),
                      AppColors.primaryPurple.withOpacity(0.05),
                      AppColors.white,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 90.0, 24.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Talk with Support',
                        style: textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 25),
                      // ✅ Enhanced Quick Input Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quickQueryInputController,
                                decoration: InputDecoration(
                                  hintText: 'Ask a quick question...',
                                  hintStyle: textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textLight.withOpacity(0.8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                                cursorColor: AppColors.primaryPurple,
                                maxLines: 3,
                                minLines: 1,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _handleQuickQuery(),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Icon(Icons.mic, color: AppColors.textLight.withOpacity(0.7)),
                            const SizedBox(width: 12),
                            // ✅ Enhanced send button with loading state
                            Obx(() => GestureDetector(
                              onTap: queryController.isLoading ? null : _handleQuickQuery,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: queryController.isLoading
                                      ? AppColors.textLight
                                      : AppColors.accentNeon,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentNeon.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: queryController.isLoading
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                  ),
                                )
                                    : const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Previous Queries Section - Enhanced glassmorphic background
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 25.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'My Recent Queries',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Obx(
                                      () => IconButton(
                                    icon: Icon(
                                      queryController.isLoading
                                          ? Icons.hourglass_empty_rounded
                                          : Icons.refresh_rounded,
                                      color: AppColors.textMedium,
                                    ),
                                    onPressed: queryController.isLoading
                                        ? null
                                        : queryController.refreshMyQueries,
                                    tooltip: 'Refresh Queries',
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 320,
                              decoration: BoxDecoration(
                                color: AppColors.neutralBackground,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: AppColors.textLight.withOpacity(0.1), width: 0.5),
                              ),
                              child: Obx(() {
                                if (queryController.isLoading && queryController.myQueries.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(color: AppColors.accentNeon),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Loading your queries...',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (queryController.myQueries.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inbox_rounded, size: 70, color: AppColors.textLight.withOpacity(0.4)),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No queries raised yet.\nTap "Raise Query" to start one!',
                                            style: textTheme.bodyLarge?.copyWith(
                                              fontSize: 16,
                                              color: AppColors.textMedium.withOpacity(0.7),
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: _showRaiseQueryDialog,
                                            icon: Icon(Icons.add),
                                            label: Text('Raise Your First Query'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryPurple,
                                              foregroundColor: AppColors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(25),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return RefreshIndicator(
                                  onRefresh: () async {
                                    await queryController.refreshMyQueries();
                                  },
                                  color: AppColors.primaryPurple,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: queryController.myQueries.length,
                                    itemBuilder: (context, index) {
                                      final query = queryController.myQueries[index];
                                      final bool hasUnreadAdminReply = query.replies != null &&
                                          query.replies!.isNotEmpty &&
                                          query.replies!.last.isAdmin &&
                                          !(query.isRead ?? false);

                                      return InkWell(
                                        onTap: () => _navigateToQueryDetail(query),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: hasUnreadAdminReply
                                                ? Border.all(color: AppColors.accentNeon.withOpacity(0.3), width: 1)
                                                : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.textDark.withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Status/New Indicator
                                              Container(
                                                width: 6,
                                                height: 40,
                                                margin: const EdgeInsets.only(right: 12),
                                                decoration: BoxDecoration(
                                                  color: hasUnreadAdminReply
                                                      ? AppColors.accentNeon
                                                      : queryController.getStatusColor(query.status.toString()),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                              ),
                                              // Icon
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                                                child: Icon(
                                                  hasUnreadAdminReply
                                                      ? Icons.mark_unread_chat_alt
                                                      : Icons.chat_bubble_outline,
                                                  color: AppColors.primaryPurple,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 15.0),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      query.title,
                                                      style: textTheme.titleMedium?.copyWith(
                                                        fontSize: 16,
                                                        fontWeight: hasUnreadAdminReply
                                                            ? FontWeight.w700
                                                            : FontWeight.w600,
                                                        color: AppColors.textDark,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      query.message.length > 50
                                                          ? '${query.message.substring(0, 50)}...'
                                                          : query.message,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: textTheme.bodySmall?.copyWith(
                                                        fontSize: 12,
                                                        color: AppColors.textMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10.0),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    DateFormat('MMM d').format(query.createdAt),
                                                    style: textTheme.labelSmall?.copyWith(
                                                      fontSize: 10,
                                                      color: AppColors.textLight,
                                                    ),
                                                  ),
                                                  if (hasUnreadAdminReply)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 5),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.accentNeon,
                                                          borderRadius: BorderRadius.circular(18),
                                                        ),
                                                        child: Text(
                                                          'NEW',
                                                          style: textTheme.labelSmall?.copyWith(
                                                            fontSize: 9,
                                                            color: AppColors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (!hasUnreadAdminReply && (query.status == 'resolved' || query.status == 'closed'))
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 5),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: queryController.getStatusColor(query.status.toString()).withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(18),
                                                        ),
                                                        child: Text(
                                                          query.status!.capitalizeFirst!,
                                                          style: textTheme.labelSmall?.copyWith(
                                                            fontSize: 9,
                                                            color: queryController.getStatusColor(query.status.toString()),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  // ✅ Add arrow indicator
                                                  const SizedBox(height: 4),
                                                  Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 12,
                                                    color: AppColors.textLight,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.1), width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
