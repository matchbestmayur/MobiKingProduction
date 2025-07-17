/*
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
import 'query_detail_screen.dart'; // <--- NEW: Import the QueryDetailScreen

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  final QueryGetXController queryController = Get.put(QueryGetXController());
  final TextEditingController _quickQueryInputController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      body: CustomScrollView(
        slivers: [
          // Top Section: 'Talk with Support' and Quick Input - Enhanced for Blinkit feel
          SliverAppBar(
            expandedHeight: 240.0, // Slightly more expanded for visual impact
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0, // No shadow for a cleaner look
            backgroundColor: AppColors.neutralBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                // Vibrant linear gradient background
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.15), // Stronger start color
                      AppColors.primaryPurple.withOpacity(0.05), // Lighter end color
                      AppColors.white, // Blending smoothly into white
                    ],
                    stops: const [0.0, 0.5, 1.0], // Control gradient spread
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
                          fontSize: 32, // Larger, bolder title
                          fontWeight: FontWeight.w900, // Extra bold
                          color: AppColors.textDark,
                          letterSpacing: -0.5, // Tighter spacing for modern feel
                        ),
                      ),
                      const SizedBox(height: 25), // More spacing
                      // Prompt/Input Field - Modernized
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // Increased vertical padding
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(36), // More rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.15), // More prominent shadow
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
                                  hintStyle: textTheme.bodyLarge?.copyWith( // Use bodyLarge for hints
                                    color: AppColors.textLight.withOpacity(0.8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: textTheme.bodyLarge?.copyWith( // Use bodyLarge for input text
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                                cursorColor: AppColors.primaryPurple,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Icon(Icons.mic, color: AppColors.textLight.withOpacity(0.7)), // Softer mic icon
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                if (_quickQueryInputController.text.isNotEmpty) {
                                  Get.snackbar(
                                    'Quick Question',
                                    'Sent: "${_quickQueryInputController.text}"',
                                    backgroundColor: AppColors.accentNeon, // Use accent for quick feedback
                                    colorText: AppColors.white,
                                    snackPosition: SnackPosition.TOP, // Consistent with other snackbars
                                  );
                                  _quickQueryInputController.clear();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14), // Larger tap target
                                decoration: BoxDecoration(
                                  color: AppColors.accentNeon, // Bright, distinct send button
                                  borderRadius: BorderRadius.circular(30), // Perfectly circular
                                  boxShadow: [ // Add subtle shadow to send button
                                    BoxShadow(
                                      color: AppColors.accentNeon.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
                              ),
                            ),
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
                  // Glassmorphic container for the entire section
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25), // More rounded
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.7), // Lighter, more translucent white
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2), width: 1.0), // Subtler border
                          boxShadow: [
                            BoxShadow( // Gentle shadow for depth
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20.0), // Increased padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'My Recent Queries', // More engaging title
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Obx(
                                      () => IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: AppColors.textMedium), // Rounded refresh icon
                                    onPressed: queryController.isLoading ? null : queryController.refreshMyQueries,
                                    tooltip: 'Refresh Queries',
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Container for the query list - Now has a slightly off-white background
                            Container(
                              height: 320, // Increased height for more queries
                              decoration: BoxDecoration(
                                color: AppColors.neutralBackground, // Slightly off-white/light gray for list background
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: AppColors.textLight.withOpacity(0.1), width: 0.5), // Subtle border
                              ),
                              child: Obx(() {
                                if (queryController.isLoading && queryController.myQueries.isEmpty) {
                                  return Center(
                                    child: CircularProgressIndicator(color: AppColors.accentNeon),
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
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: queryController.myQueries.length,
                                  itemBuilder: (context, index) {
                                    final query = queryController.myQueries[index];
                                    final bool hasUnreadAdminReply = query.replies != null && query.replies!.isNotEmpty &&
                                        query.replies!.last.isAdmin &&
                                        !(query.isRead ?? false);

                                    return InkWell(
                                      onTap: () {
                                        queryController.selectQuery(query);
                                        Get.to(() => QueryDetailScreen());
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), // Adjusted margins
                                        padding: const EdgeInsets.all(12.0), // Increased padding
                                        decoration: BoxDecoration(
                                          color: AppColors.white, // Individual card background
                                          borderRadius: BorderRadius.circular(12), // Rounded corners for each item
                                          boxShadow: [ // Subtle shadow for each item
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
                                              width: 6, // Vertical indicator bar
                                              height: 40, // Height to match content
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                color: hasUnreadAdminReply ? AppColors.accentNeon : queryController.getStatusColor(query.status.toString()),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                            // Icon
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                                              child: Icon(
                                                Icons.chat_bubble_outline,
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
                                                    style: textTheme.titleMedium?.copyWith( // Larger title for query item
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
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
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Larger padding
                                                      decoration: BoxDecoration(
                                                        color: AppColors.accentNeon,
                                                        borderRadius: BorderRadius.circular(18), // More rounded
                                                      ),
                                                      child: Text(
                                                        'NEW',
                                                        style: textTheme.labelSmall?.copyWith(
                                                          fontSize: 9, // Slightly larger font
                                                          color: AppColors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                // Display status badge for resolved/closed queries
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
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

// NOTE: _buildActionCard is no longer directly used in the new "Quick Actions" section.
// I've kept it here commented out in case you wish to revert or reuse it elsewhere.
*/
/*
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
  *//*

}*/
