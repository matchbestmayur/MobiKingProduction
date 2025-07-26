import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _sections = [
    {
      'title': 'Introduction',
      'content':
      'We are committed to protecting your privacy. This Privacy Policy outlines how we collect, use, and safeguard your personal data when using our services.'
    },
    {
      'title': 'Information Collection',
      'content':
      'We may collect information such as your name, email address, and usage behavior to improve our services and personalize your experience.'
    },
    {
      'title': 'Use of Information',
      'content':
      'The collected information is primarily used for improving user experience, providing customer support, processing transactions, and delivering a more tailored service. We do not sell or rent your personal data to third parties.'
    },
    {
      'title': 'Data Security',
      'content':
      'We implement a variety of security measures to maintain the safety of your personal information when you place an order or enter, submit, or access your personal information. However, no method of transmission over the Internet or method of electronic storage is 100% secure.'
    },
    {
      'title': 'Changes to this Policy',
      'content':
      'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. You are advised to review this Privacy Policy periodically for any changes.'
    },
    {
      'title': 'Contact Us',
      'content':
      'If you have any questions regarding this Privacy Policy, please feel free to contact our support team at support@mobiking.com.'
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

    // Start animation after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Privacy Policy',
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
          // Centered heading with dividers
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
                  heading.toUpperCase(), // Converts text to uppercase
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
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
          // Description container with neutral background
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