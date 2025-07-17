// Path: lib/app/modules/order_history/shipping_details_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:mobiking/app/data/scan_model.dart';

import '../../data/order_model.dart';
import '../../themes/app_theme.dart'; // Ensure this path is correct
// Import your OrderModel and ScanEntry classes


// Only import MilestoneTimeline and its Milestone model
import 'package:animated_milestone/view/milestone_timeline.dart';
import 'package:animated_milestone/model/milestone.dart' as am_milestone; // Alias for clarity


class ShippingDetailsScreen extends StatelessWidget {
  // Make the OrderModel a required parameter
  final OrderModel order;

  const ShippingDetailsScreen({Key? key, required this.order}) : super(key: key); // Make it required

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Access the scans directly from the 'order' property
    final List<Scan>? scans = order.scans;

    // Default values if no scans are available
    String currentActivity = 'No updates yet.';
    String currentLocation = 'N/A';
    String currentStatusLabel = 'Pending';
    DateTime? lastScanDateTime;

    // Get the latest scan details if available
    if (scans!.isNotEmpty) {
      final Scan lastScan = scans.last;
      currentActivity = lastScan.activity;
      currentLocation = lastScan.location;
      currentStatusLabel = lastScan.srStatusLabel;
      try {
        lastScanDateTime = DateTime.parse(lastScan.date);
      } catch (e) {
        debugPrint('Error parsing date for last scan: ${lastScan.date} - $e');
      }
    }

    // Map your tracking statuses to the Amazon-like overall milestones
    final List<String> overallMilestones = [
      'Order Placed',
      'Shipped',
      'In Transit',
      'Out for Delivery',
      'Delivered',
    ];

    // Determine which overall milestone is active based on the latest scan status
    int currentOverallMilestoneIndex = 0; // Default to 'Order Placed'

    if (scans.isNotEmpty) {
      final String latestSrStatusLabel = scans.last.srStatusLabel.toUpperCase();
      final String latestStatus = scans.last.status.toUpperCase();
      final String latestActivity = scans.last.activity.toUpperCase();

      if (latestSrStatusLabel.contains('DELIVERED') || latestStatus.contains('DELIVERED')) {
        currentOverallMilestoneIndex = 4; // Delivered
      } else if (latestSrStatusLabel.contains('OUT FOR DELIVERY') || latestStatus.contains('OUT_FOR_DELIVERY')) {
        currentOverallMilestoneIndex = 3; // Out for Delivery
      } else if (latestSrStatusLabel.contains('IN TRANSIT') || latestStatus.contains('IN_TRANSIT') || latestActivity.contains('HUB')) {
        currentOverallMilestoneIndex = 2; // In Transit
      } else if (latestSrStatusLabel.contains('PICKED UP') || latestStatus.contains('PICKED_UP')) {
        currentOverallMilestoneIndex = 1; // Shipped
      } else if (latestSrStatusLabel.contains('MANIFEST GENERATED') || latestStatus.contains('MANIFESTED') || latestStatus.contains('ORDER_PLACED')) {
        currentOverallMilestoneIndex = 0; // Order Placed (or Manifested)
      }
    }


    List<am_milestone.Milestone> combinedMilestones = [];

    // 1. Add overall progress milestones first
    for (int i = 0; i < overallMilestones.length; i++) {
      String milestoneTitle = overallMilestones[i];
      bool isActive = i <= currentOverallMilestoneIndex; // Highlight up to the current overall status

      // Only add detailed description for the *current* active overall milestone
      String? milestoneDescription;
      if (i == currentOverallMilestoneIndex) {
        milestoneDescription = 'Your package is $currentActivity at $currentLocation.';
      } else if (i < currentOverallMilestoneIndex) {
        // Optionally, you can add a brief 'completed' message for past milestones
        milestoneDescription = 'Completed.';
      }

      combinedMilestones.add(
        am_milestone.Milestone(
          isActive: isActive,
          title: Text(
            milestoneTitle,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          child: milestoneDescription != null
              ? Text(
            milestoneDescription,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
          )
              : const SizedBox.shrink(),
          icon: i < currentOverallMilestoneIndex // Use check icon for completed overall milestones
              ? Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
              : null,
        ),
      );
    }

    // Add a separator/header for Detailed History if there are scans
    if (scans.isNotEmpty) {
      combinedMilestones.add(
        am_milestone.Milestone( // Adding a "start of details" milestone
          isActive: true, // Always active as it's the start of the detailed log
          title: Text(
            'Detailed History:',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          child: const SizedBox.shrink(),
          icon: Icon(Icons.history, color: AppColors.textDark, size: 20), // Icon for history
        ),
      );
    }


    // 2. Append detailed scan history (reversed to show newest first)
    // Filter out initial placeholder scans if they are purely "order placed" and we have more detailed ones
    final List<Scan> filteredScans = scans.where((scan) {
      // You might want to filter out very generic 'order placed' if more specific scans follow
      return !(scan.status.toUpperCase() == 'ORDER_PLACED' && scans.length > 1);
    }).toList().reversed.toList(); // Reverse to show newest first

    if (filteredScans.isEmpty && scans.isNotEmpty) {
      // If filtering resulted in empty but original scans existed, just show all original scans
      // This handles cases where only 'ORDER_PLACED' scan might be present initially
      filteredScans.addAll(scans.reversed);
    } else if (scans.isEmpty) {
      // If there are no scans at all, add a single placeholder milestone
      combinedMilestones.add(
        am_milestone.Milestone(
          isActive: true,
          title: Text(
            'No tracking information available yet.',
            style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
          child: const SizedBox.shrink(),
        ),
      );
    }


    for (int i = 0; i < filteredScans.length; i++) {
      final Scan scan = filteredScans[i];
      final String activity = scan.activity;
      final String location = scan.location;

      DateTime scanDateTime;
      String formattedDate = 'N/A';
      try {
        scanDateTime = DateTime.parse(scan.date);
        formattedDate = DateFormat('dd MMM, hh:mm a').format(scanDateTime.toLocal());
      } catch (e) {
        debugPrint('Error parsing date for scan: ${scan.date} - $e');
      }

      bool isLatestDetailedScan = (i == 0); // The first item in reversed/filtered list is the very latest detailed scan

      combinedMilestones.add(
        am_milestone.Milestone(
          isActive: isLatestDetailedScan, // Highlight only the very latest detailed scan
          // Only show custom icon if not delivered (last overall milestone)
          icon: isLatestDetailedScan && currentOverallMilestoneIndex < overallMilestones.length - 1
              ? const Icon(Icons.circle, color: AppColors.info, size: 12) // Small dot for detailed scans
              : null,
          title: Text(
            activity,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
              color: AppColors.textDark,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
              ),
              Text(
                location,
                style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                    overflow: TextOverflow.ellipsis
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine estimated delivery date (dummy for now, based on current overall milestone)
    String estimatedDelivery = 'Not available';
    if (currentOverallMilestoneIndex < overallMilestones.length - 1) { // If not yet delivered
      // Placeholder: In a real app, this would come from the API or a more complex calculation
      estimatedDelivery = DateFormat('EEEE, MMM d, y').format(
          DateTime.now().add(const Duration(days: 2)) // Example: 2 days from now
      );
    } else if (currentOverallMilestoneIndex == overallMilestones.length - 1 && lastScanDateTime != null) {
      // If delivered, show the actual delivery date
      estimatedDelivery = 'Delivered on ${DateFormat('EEEE, MMM d, y').format(lastScanDateTime.toLocal())}';
    }


    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          'Shipment Tracking',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card with Current Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textDark.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overallMilestones[currentOverallMilestoneIndex], // Display current overall milestone
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.success, // Highlight current status in success color
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your package is currently: $currentActivity at $currentLocation.',
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated delivery: $estimatedDelivery',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Spacing below the current status card

            // Combined Overall Progress and Detailed Tracking Timeline
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textDark.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MilestoneTimeline(
                milestones: combinedMilestones,
                color: AppColors.success, // Color for active elements
                circleRadius: 8, // Adjust circle size for main milestones
                stickThickness: 2, // Thinner stick
                activeWithStick: true, // Connect active milestones with the stick
                showLastStick: true, // Show stick for the last milestone
                greyoutContentWithInactive: false, // Don't grey out content of inactive milestones
                milestoneIntervalDurationInMillis: 300, // Speed of animation
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}