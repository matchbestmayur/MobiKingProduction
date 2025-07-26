import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class BillSection extends StatefulWidget {
  final int itemTotal;
  final int deliveryCharge;

  const BillSection({
    Key? key,
    required this.itemTotal,
    required this.deliveryCharge,
  }) : super(key: key);

  @override
  State<BillSection> createState() => _BillSectionState();
}

class _BillSectionState extends State<BillSection> {
  bool _hasGstNumber = false;
  bool _showGstInput = false;
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();

  @override
  void dispose() {
    _gstController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }

  double get _gstAmount {
    if (!_hasGstNumber || !_showGstInput || _gstController.text.isEmpty) return 0.0;
    final customGst = double.tryParse(_gstController.text) ?? 0.0;
    return (widget.itemTotal * customGst) / 100;
  }

  double get _total {
    return widget.itemTotal + widget.deliveryCharge + _gstAmount;
  }

  void _showGstDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GST Information',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do you have a GST number?',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GST Number Option
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _hasGstNumber,
                        onChanged: (value) {
                          setDialogState(() {
                            _hasGstNumber = value ?? false;
                            if (_hasGstNumber) {
                              _showGstInput = true;
                            }
                          });
                        },
                        activeColor: AppColors.primaryPurple,
                      ),
                      Expanded(
                        child: Text(
                          'Yes, I have a GST number',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // No GST Number Option
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _hasGstNumber,
                        onChanged: (value) {
                          setDialogState(() {
                            _hasGstNumber = value ?? true;
                            if (!_hasGstNumber) {
                              _showGstInput = false;
                              _gstController.clear();
                              _gstNumberController.clear();
                            }
                          });
                        },
                        activeColor: AppColors.primaryPurple,
                      ),
                      Expanded(
                        child: Text(
                          'No, I don\'t have GST',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // GST Number Input (if has GST)
                  if (_hasGstNumber) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _gstNumberController,
                      decoration: InputDecoration(
                        labelText: 'GST Number',
                        hintText: 'Enter your GST number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.numbers,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textMedium),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showGstInput = _hasGstNumber;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with GST button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bill Details",
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              // GST Button
              GestureDetector(
                onTap: _showGstDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hasGstNumber
                        ? AppColors.primaryPurple.withOpacity(0.1)
                        : AppColors.neutralBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasGstNumber
                          ? AppColors.primaryPurple.withOpacity(0.3)
                          : AppColors.textLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 16,
                        color: _hasGstNumber
                            ? AppColors.primaryPurple
                            : AppColors.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasGstNumber ? 'GST' : 'Add GST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _hasGstNumber
                              ? AppColors.primaryPurple
                              : AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Divider(color: AppColors.neutralBackground, thickness: 1),
          const SizedBox(height: 4),

          _buildBillRow("Items total", widget.itemTotal.toDouble(), textTheme),
          _buildBillRow("Delivery charge", widget.deliveryCharge.toDouble(), textTheme),

          // GST Section (only show if has GST)
          if (_hasGstNumber && _showGstInput)
            _buildGstSection(textTheme),

          const SizedBox(height: 4),
          Divider(color: AppColors.textMedium.withOpacity(0.5), thickness: 1.5),
          const SizedBox(height: 4),

          _buildBillRow("Grand total", _total, textTheme, isBold: true),
        ],
      ),
    );
  }

  Widget _buildGstSection(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "GST",
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                  fontSize: 14,
                ),
              ),
              if (_gstController.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${_gstController.text}%",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            "₹${_gstAmount.toStringAsFixed(2)}",
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, double value, TextTheme textTheme, {bool isBold = false}) {
    final TextStyle labelStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      color: isBold ? AppColors.textDark : AppColors.textMedium,
      fontSize: isBold ? 16 : 14,
    ) ?? const TextStyle();

    final TextStyle valueStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      color: isBold ? AppColors.textDark : AppColors.textMedium,
      fontSize: isBold ? 16 : 14,
    ) ?? const TextStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text("₹${value.toStringAsFixed(2)}", style: valueStyle),
        ],
      ),
    );
  }
}
