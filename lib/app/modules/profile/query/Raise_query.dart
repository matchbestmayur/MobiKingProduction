import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/query_getx_controller.dart';
import '../../../themes/app_theme.dart';

class RaiseQueryDialog extends StatefulWidget {
  final String? orderId;

  const RaiseQueryDialog({super.key, this.orderId});

  @override
  State<RaiseQueryDialog> createState() => _RaiseQueryDialogState();
}

class _RaiseQueryDialogState extends State<RaiseQueryDialog> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final QueryGetXController queryController = Get.find<QueryGetXController>();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      _titleController.text = 'Query for Order ID: ${widget.orderId}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _titleFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _submitQuery() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await queryController.raiseQuery(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        orderId: widget.orderId,
      );
      _showSuccessSnackbar();
      Get.back(); // Dismiss dialog
    } catch (e) {
      debugPrint('Error submitting query: $e');
    }
  }

  void _showSuccessSnackbar() {
    HapticFeedback.mediumImpact();
    Get.snackbar(
      'Query Submitted! 🎉',
      'Your query has been successfully submitted.',
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
          horizontal: mq.size.width * 0.05,
          vertical: mq.size.height * 0.06
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // This ensures dialog resizes for the keyboard!
            padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: mq.size.height * 0.9
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // This respects the content!
                    children: [
                      _buildHeader(textTheme),
                      Flexible(
                        fit: FlexFit.loose,
                        child: _buildContent(textTheme),
                      ),
                      _buildActions(textTheme),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryPurple.withOpacity(0.04),
          AppColors.lightPurple.withOpacity(0.01),
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
          child: Icon(Icons.help_outline_rounded, color: AppColors.primaryPurple, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Raise a Query',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'re here to help! Let us know what\'s on your mind.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildContent(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitleField(textTheme),
          const SizedBox(height: 20),
          _buildMessageField(textTheme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTitleField(TextTheme textTheme) => TextFormField(
    controller: _titleController,
    focusNode: _titleFocus,
    cursorColor: AppColors.primaryPurple,
    textInputAction: TextInputAction.next,
    onFieldSubmitted: (_) => _messageFocus.requestFocus(),
    decoration: InputDecoration(
      labelText: 'Query Title *',
      hintText: 'e.g.: Issue with delivery of order #12345',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: AppColors.neutralBackground.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark, fontSize: 16),
    validator: (value) {
      if (value == null || value.trim().isEmpty) return 'Please enter a title for your query';
      if (value.trim().length < 3) return 'Title must be at least 3 characters';
      return null;
    },
  );

  Widget _buildMessageField(TextTheme textTheme) => TextFormField(
    controller: _messageController,
    focusNode: _messageFocus,
    cursorColor: AppColors.primaryPurple,
    textInputAction: TextInputAction.done,
    maxLines: 6,
    minLines: 4,
    decoration: InputDecoration(
      labelText: 'Detailed Message *',
      hintText: 'Describe your query in detail, including relevant dates/order numbers...',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: AppColors.neutralBackground.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark, fontSize: 16, height: 1.4),
    validator: (value) {
      if (value == null || value.trim().isEmpty) return 'Please describe your query in detail';
      if (value.trim().length < 10) return 'Message must be at least 10 characters long';
      return null;
    },
    keyboardType: TextInputType.multiline,
    textAlignVertical: TextAlignVertical.top,
    enableInteractiveSelection: true,
  );

  Widget _buildActions(TextTheme textTheme) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.neutralBackground.withOpacity(0.3),
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              backgroundColor: AppColors.white,
              side: BorderSide(color: AppColors.lightGreyBackground, width: 1.5),
              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: queryController.isLoading ? 0 : 4,
              shadowColor: AppColors.primaryPurple.withOpacity(0.3),
            ),
            child: queryController.isLoading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20, width: 20,
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
                Icon(Icons.send_rounded, size: 20, color: AppColors.white),
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
