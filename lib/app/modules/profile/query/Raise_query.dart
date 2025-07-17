// lib/widgets/raise_query_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/query_getx_controller.dart';
import '../../../themes/app_theme.dart'; // Import AppColors and AppTheme

class RaiseQueryDialog extends StatefulWidget {
  // NEW: Add an optional orderId field
  final String? orderId;

  // The onAddQuery callback is no longer needed here as the dialog directly
  // interacts with the QueryGetXController to submit the query.
  // UPDATED: Constructor now accepts orderId
  const RaiseQueryDialog({
    super.key,
    this.orderId, // Make orderId optional
  });

  @override
  State<RaiseQueryDialog> createState() => _RaiseQueryDialogState();
}

class _RaiseQueryDialogState extends State<RaiseQueryDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final QueryGetXController queryController = Get.find<QueryGetXController>();

  @override
  void initState() {
    super.initState();
    // Pre-fill the title with the order ID if provided, for user convenience.
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      _titleController.text = 'Query for Order ID: ${widget.orderId}';
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// This method is called when the "Submit Query" button is pressed.
  /// It now passes the widget's orderId to the controller.
  Future<void> _submitQuery() async {
    if (_formKey.currentState?.validate() ?? false) {
      print('RaiseQueryDialog: _submitQuery called. Attempting to raise query...');

      await queryController.raiseQuery(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        orderId: widget.orderId, // NEW: Pass the orderId from the widget
      );

      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        title: Text(
          'Raise a Query',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  cursorColor: AppColors.primaryPurple,
                  decoration: InputDecoration(
                    labelText: 'Query Title',
                    hintText: 'e.g., Issue with delivery of order #12345',
                    labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.textLight.withOpacity(0.9), fontSize: 15),
                    hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textLight.withOpacity(0.6), fontSize: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.lightPurple, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.lightPurple.withOpacity(0.7), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.danger, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.danger, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.neutralBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark, fontSize: 16),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _messageController,
                  cursorColor: AppColors.primaryPurple,
                  decoration: InputDecoration(
                    labelText: 'Detailed Message',
                    hintText: 'Please describe your query in detail, including any relevant dates or order numbers.',
                    labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.textLight.withOpacity(0.9), fontSize: 15),
                    hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textLight.withOpacity(0.6), fontSize: 15),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.lightPurple, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.lightPurple.withOpacity(0.7), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.danger, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.danger, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.neutralBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark, fontSize: 16),
                  maxLines: 7,
                  minLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Message cannot be empty.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textLight,
              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 15),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!queryController.isLoading) {
                _submitQuery();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPurple,
              foregroundColor: AppColors.white,
              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 6,
            ),
            child: Obx(
                  () => queryController.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text('Submit Query'),
            ),
          ),
        ],
      ),
    );
  }
}