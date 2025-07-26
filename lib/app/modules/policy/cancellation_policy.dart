import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../themes/app_theme.dart';

class CancellationPolicyScreen extends StatefulWidget {
  const CancellationPolicyScreen({super.key});

  @override
  State<CancellationPolicyScreen> createState() => _CancellationPolicyScreenState();
}

class _CancellationPolicyScreenState extends State<CancellationPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _sections = [
    {
      'title': 'Overview',
      'content':
      'This Cancellation Policy outlines the conditions under which you can cancel your services or orders made through our app. Please read it carefully before proceeding with any transactions.',
    },
    {
      'title': 'Cancellation Timeframes',
      'content':
      'Eligibility for cancellation depends on the type of service or product and the time elapsed since the order was placed. Generally, orders can be cancelled without charge within a specific window (e.g., 15–30 minutes for quick deliveries, or before dispatch for scheduled services). Refer to specific product/service details for exact terms.',
    },
    {
      'title': 'How to Cancel an Order',
      'content':
      'To cancel an eligible order, navigate to the “My Orders” or “Active Services” section within the app. Select the order you wish to cancel and follow the prompts. If direct cancellation is not available, please contact our customer support immediately.',
    },
    {
      'title': 'Charges & Refunds',
      'content':
      'Some cancellations, especially those made after the specified free cancellation window or for custom/perishable items, may be subject to a cancellation fee or may not be eligible for a full refund. Any applicable charges will be clearly communicated during the cancellation process. Refunds, if eligible, will be processed as per our Refund Policy, typically within 5–7 business days.',
    },
    {
      'title': 'Force Majeure',
      'content':
      'We reserve the right to cancel any order due to unforeseen circumstances, including but not limited to, natural disasters, strikes, technical issues, or unavailability of products/services. In such cases, a full refund will be initiated.',
    },
    {
      'title': 'Changes to this Policy',
      'content':
      'We may update this Cancellation Policy periodically. Any changes will be posted on this page and will become effective immediately upon posting. Your continued use of the service after such modifications constitutes your acceptance of the new policy.',
    },
    {
      'title': 'Contact Us',
      'content':
      'For any assistance with cancellations or queries regarding this policy, please contact our dedicated support team at support@mobiking.com.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animations = List.generate(
      _sections.length,
          (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            (index / _sections.length) * 0.6,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Cancellation Policy',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_sections.length, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Opacity(
                  opacity: _animations[index].value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - _animations[index].value)),
                    child: child,
                  ),
                );
              },
              child: _buildSection(
                textTheme,
                _sections[index]['title']!,
                _sections[index]['content']!,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSection(TextTheme textTheme, String heading, String paragraph) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading with dividers
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.textMedium.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  heading.toUpperCase(),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.textMedium.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Paragraph container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neutralBackground.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textMedium.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              paragraph,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textMedium,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
