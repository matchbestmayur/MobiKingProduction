// lib/widgets/raise_query_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/query_getx_controller.dart';
import '../../../themes/app_theme.dart';

class RaiseQueryDialog extends StatefulWidget {
  final String? orderId;

  const RaiseQueryDialog({
    super.key,
    this.orderId,
  });

  @override
  State<RaiseQueryDialog> createState() => _RaiseQueryDialogState();
}

class _RaiseQueryDialogState extends State<RaiseQueryDialog> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final QueryGetXController queryController = Get.find<QueryGetXController>();

  // Focus nodes for better UX
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Pre-fill the title with the order ID if provided
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      _titleController.text = 'Query for Order ID: ${widget.orderId}';
    }

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _titleFocus.dispose();
    _messageFocus.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Enhanced submit query method with better error handling and UX
  Future<void> _submitQuery() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      debugPrint('RaiseQueryDialog: Submitting query...');

      await queryController.raiseQuery(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        orderId: widget.orderId,
      );

      // Success feedback
      _showSuccessSnackbar();

      // Close dialog with animation
      await _closeDialog();

    } catch (e) {
      debugPrint('Error submitting query: $e');
    }
  }

  /// Close dialog with animation
  Future<void> _closeDialog() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    if (mounted) {
      Get.back();
    }
  }

  /// Show success snackbar
  void _showSuccessSnackbar() {
    HapticFeedback.mediumImpact();
    _showModernSnackbar(
      'Query Submitted! 🎉',
      'Your query has been successfully submitted. We\'ll get back to you soon.',
      icon: Icons.check_circle_outline,
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.1,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: size.height * 0.8,
              maxWidth: 500,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(textTheme),
                  Flexible(
                    child: _buildContent(textTheme),
                  ),
                  _buildActions(textTheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.05),
            AppColors.lightPurple.withOpacity(0.02),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: AppColors.primaryPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Raise a Query',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re here to help! Let us know what\'s on your mind.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textMedium,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build content section
  Widget _buildContent(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitleField(textTheme),
              const SizedBox(height: 20),
              _buildMessageField(textTheme),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Build title field
  Widget _buildTitleField(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.title_rounded,
              color: AppColors.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Query Title',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          focusNode: _titleFocus,
          cursorColor: AppColors.primaryPurple,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _messageFocus.requestFocus(),
          decoration: InputDecoration(
            hintText: 'e.g., Issue with delivery of order #12345',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight.withOpacity(0.6),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.lightGreyBackground, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.lightGreyBackground, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            filled: true,
            fillColor: AppColors.neutralBackground.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.textMedium,
                size: 20,
              ),
            ),
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textDark,
            fontSize: 16,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title for your query';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Build message field
  Widget _buildMessageField(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.message_outlined,
              color: AppColors.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Detailed Message',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          focusNode: _messageFocus,
          cursorColor: AppColors.primaryPurple,
          textInputAction: TextInputAction.done,
          maxLines: 6,
          minLines: 4,
          decoration: InputDecoration(
            hintText: 'Please describe your query in detail, including any relevant dates or order numbers...',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight.withOpacity(0.6),
              fontSize: 14,
            ),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.lightGreyBackground, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.lightGreyBackground, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            filled: true,
            fillColor: AppColors.neutralBackground.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textDark,
            fontSize: 16,
            height: 1.4,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please describe your query in detail';
            }
            if (value.trim().length < 10) {
              return 'Message must be at least 10 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Build actions section
  Widget _buildActions(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.neutralBackground.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await _closeDialog();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMedium,
                backgroundColor: AppColors.white,
                side: BorderSide(color: AppColors.lightGreyBackground, width: 1.5),
                textStyle: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
              onPressed: queryController.isLoading ? null : _submitQuery,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.textLight.withOpacity(0.3),
                textStyle: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: queryController.isLoading ? 0 : 4,
                shadowColor: AppColors.primaryPurple.withOpacity(0.3),
              ),
              child: queryController.isLoading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Submitting...'),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text('Submit Query'),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }
}

/// Enhanced modern snackbar with better styling
void _showModernSnackbar(
    String title,
    String message, {
      IconData? icon,
      Color? backgroundColor,
      Color? colorText,
      bool isError = false,
      SnackPosition snackPosition = SnackPosition.TOP,
      Duration? duration,
    }) {
  if (Get.isSnackbarOpen) Get.back();

  Get.snackbar(
    '',
    '',
    titleText: Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (colorText ?? AppColors.white).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorText ?? AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorText ?? AppColors.white,
            ),
          ),
        ),
      ],
    ),
    messageText: Padding(
      padding: EdgeInsets.only(left: icon != null ? 42 : 0),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: (colorText ?? AppColors.white).withOpacity(0.9),
        ),
      ),
    ),
    backgroundColor: backgroundColor ??
        (isError ? AppColors.danger : AppColors.success),
    snackPosition: snackPosition,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    borderRadius: 16,
    animationDuration: const Duration(milliseconds: 400),
    duration: duration ?? const Duration(seconds: 3),
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
    forwardAnimationCurve: Curves.easeOutBack,
    reverseAnimationCurve: Curves.easeInBack,
    boxShadows: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
