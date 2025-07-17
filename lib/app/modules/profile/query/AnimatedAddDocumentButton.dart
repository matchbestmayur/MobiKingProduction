import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimatedAddDocumentButton extends StatefulWidget {
  final VoidCallback? onDocumentAdded; // Callback for when a document is added

  const AnimatedAddDocumentButton({Key? key, this.onDocumentAdded}) : super(key: key);

  @override
  _AnimatedAddDocumentButtonState createState() => _AnimatedAddDocumentButtonState();
}

class _AnimatedAddDocumentButtonState extends State<AnimatedAddDocumentButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  bool _isRotated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value * 3.14, // Rotate by PI (180 degrees)
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isRotated = !_isRotated;
                if (_isRotated) {
                  _animationController.forward();
                  // Optionally, show additional action buttons here (like in WhatsApp)
                  // You'll need to manage the visibility of these buttons separately.
                } else {
                  _animationController.reverse();
                  // Optionally, hide additional action buttons here.
                }
                widget.onDocumentAdded?.call(); // Call the callback
              });
            },
            backgroundColor: Colors.blue, // Customize the button color
            child: Icon(
              _isRotated ? Icons.close : Icons.add, // Toggle icon
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}