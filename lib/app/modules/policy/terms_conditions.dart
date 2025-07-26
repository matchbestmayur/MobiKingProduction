import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../themes/app_theme.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _sections = [
    {
      'title': 'Welcome',
      'content':
      'These Terms & Conditions govern your use of our app. By using our app, you agree to these terms in full.',
    },
    {
      'title': 'User Accounts',
      'content':
      'When you create an account with us, you must provide us with information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account on our Service.',
    },
    {
      'title': 'Intellectual Property',
      'content':
      'The Service and its original content, features, and functionality are and will remain the exclusive property of Mobiking and its licensors. Our trademarks and trade dress may not be used in connection with any product or service without the prior written consent of Mobiking.',
    },
    {
      'title': 'User Responsibilities',
      'content':
      'You agree to use the app only for lawful purposes and not to infringe the rights of others or restrict their usage. This includes refraining from engaging in any unlawful, fraudulent, or harmful activities.',
    },
    {
      'title': 'Limitation of Liability',
      'content':
      'In no event shall Mobiking, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages.',
    },
    {
      'title': 'Changes to Terms',
      'content':
      'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice before any new terms take effect.',
    },
    {
      'title': 'Governing Law',
      'content':
      'These Terms shall be governed and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
    },
    {
      'title': 'Contact Us',
      'content':
      'If you have any questions about these Terms & Conditions, please contact us at support@mobiking.com.',
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
          'Terms & Conditions',
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
