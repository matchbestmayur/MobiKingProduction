import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../themes/app_theme.dart';

class RefundPolicyScreen extends StatefulWidget {
  const RefundPolicyScreen({super.key});

  @override
  State<RefundPolicyScreen> createState() => _RefundPolicyScreenState();
}

class _RefundPolicyScreenState extends State<RefundPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _sections = [
    {
      'title': 'Overview',
      'content':
      'At Mobiking, we are committed to ensuring your satisfaction with our services and products. This Refund Policy outlines the conditions under which refunds may be issued.',
    },
    {
      'title': 'Eligibility for Refunds',
      'content':
      'Refund requests must typically be made within 7 days of the purchase date. Eligibility criteria vary by product/service. Generally, refunds are applicable for unused services or products found to be defective upon delivery, provided the issue is reported promptly. Digital products, completed services, and promotional/discounted offers may have different refund rules as specified at the time of purchase.',
    },
    {
      'title': 'Non-Refundable Items',
      'content':
      'Please note that certain items or services are explicitly non-refundable. These may include, but are not limited to, gift cards, subscriptions after initial use, specific perishable goods, or services where the full value has been utilized.',
    },
    {
      'title': 'Refund Process',
      'content':
      'To request a refund, please contact our support team with your order details and the reason for the refund. Once your request is received and reviewed, we will notify you of the approval or rejection. If approved, the refund will be processed to your original method of payment within 5–10 business days, depending on your bank or payment provider.',
    },
    {
      'title': 'Partial Refunds',
      'content':
      'In some cases, partial refunds may be granted for services that were partially used or products that are returned in a condition not suitable for full resale. This will be determined at our sole discretion.',
    },
    {
      'title': 'Changes to this Policy',
      'content':
      'We reserve the right to modify this Refund Policy at any time. Changes will be effective immediately upon posting to the app. Your continued use of the service after any such changes constitutes your acceptance of the new policy.',
    },
    {
      'title': 'Contact Support',
      'content':
      'If you have any questions about this Refund Policy or wish to initiate a refund request, please contact our support team directly at support@mobiking.com.',
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
          'Refund Policy',
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
