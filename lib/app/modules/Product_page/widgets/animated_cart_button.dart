// lib/screens/product_page/widgets/animated_cart_button.dart
import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Make sure this path is correct

class AnimatedCartButton extends StatefulWidget {
  final bool isInCart;
  final bool isBusy;
  final bool isOutOfStock;
  final int quantityInCart;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool canIncrement;
  final bool canDecrement;
  final TextTheme textTheme;

  const AnimatedCartButton({
    super.key,
    required this.isInCart,
    required this.isBusy,
    required this.isOutOfStock,
    required this.quantityInCart,
    this.onAdd,
    this.onIncrement,
    this.onDecrement,
    required this.canIncrement,
    required this.canDecrement,
    required this.textTheme,
  });

  @override
  State<AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<AnimatedCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<BorderRadius?> _borderRadiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Standard duration
    );

    // Initial state setup for animations
    _widthAnimation = Tween<double>(begin: 120.0, end: 120.0).animate(_controller);
    _borderRadiusAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(12),
      end: BorderRadius.circular(12),
    ).animate(_controller);
    _opacityAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);

    if (widget.isInCart) {
      _controller.value = 1.0; // Set to end state if already in cart
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isInCart != oldWidget.isInCart) {
      if (widget.isInCart) {
        _controller.forward(); // Animate to quantity controls
      } else {
        _controller.reverse(); // Animate back to add button
      }
    }

    // Update animation tweens based on current state.
    _widthAnimation = Tween<double>(
      begin: widget.isInCart ? 120.0 : _getQuantityControlsWidth(),
      end: widget.isInCart ? _getQuantityControlsWidth() : 120.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    _borderRadiusAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(12),
      end: BorderRadius.circular(12),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    _opacityAnimation = Tween<double>(
      begin: widget.isInCart ? 0.0 : 1.0,
      end: widget.isInCart ? 1.0 : 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  // Helper to calculate the width of the quantity controls dynamically
  double _getQuantityControlsWidth() {
    const double buttonSize = 30.0;
    const double textWidth = 30.0;
    const double spacing = 12.0;
    const double containerPadding = 8.0;
    return (buttonSize * 2) + textWidth + (spacing * 2) + (containerPadding * 2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    VoidCallback? onTap,
    required bool isDisabled,
    required bool isLoading,
  }) {
    final Color buttonColor = AppColors.success;
    final Color iconColor = Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDisabled ? buttonColor.withOpacity(0.5) : buttonColor,
          shape: BoxShape.circle,
        ),
        child: isLoading // Show spinner if this specific button is busy
            ? SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        )
            : Icon(
          icon,
          size: 18,
          color: isDisabled ? iconColor.withOpacity(0.5) : iconColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOutOfStock) {
      return Text(
        'Out of Stock',
        style: widget.textTheme.titleMedium?.copyWith(color: AppColors.danger),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: _borderRadiusAnimation.value, // This is fine as BorderRadiusGeometry? is accepted
            boxShadow: [
              if (!widget.isInCart || _controller.status == AnimationStatus.forward)
                BoxShadow(
                  color: AppColors.textDark.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: _borderRadiusAnimation.value!, // Null assertion is safe here
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Add Button (shows when not in cart or animating out)
                if (!widget.isInCart || _controller.status == AnimationStatus.reverse)
                  Opacity(
                    opacity: widget.isInCart ? (1.0 - _opacityAnimation.value) : 1.0,
                    child: SizedBox(
                      width: _widthAnimation.value,
                      child: ElevatedButton(
                        onPressed: widget.isBusy ? null : widget.onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: widget.isBusy
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                            : Text(
                          'Add',
                          style: widget.textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                // Quantity Controls (shows when in cart or animating in)
                if (widget.isInCart || _controller.status == AnimationStatus.forward)
                  Opacity(
                    opacity: widget.isInCart ? _opacityAnimation.value : 0.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuantityButton(
                          context: context,
                          icon: Icons.remove,
                          onTap: widget.canDecrement ? widget.onDecrement : null,
                          isDisabled: !widget.canDecrement,
                          isLoading: widget.isBusy && widget.canDecrement,
                        ),
                        const SizedBox(width: 12),
                        // Quantity Text
                        // You might want to show a spinner here if _isBusy is true
                        // and it's not specific to an increment/decrement operation,
                        // but rather a general update. For now, it stays text.
                        widget.isBusy && !widget.canDecrement && !widget.canIncrement // If busy and both buttons disabled, means general loading state for quantity.
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : Text(
                          '${widget.quantityInCart}',
                          style: widget.textTheme.titleMedium
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        _buildQuantityButton(
                          context: context,
                          icon: Icons.add,
                          onTap: widget.canIncrement ? widget.onIncrement : null,
                          isDisabled: !widget.canIncrement,
                          isLoading: widget.isBusy && widget.canIncrement,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}