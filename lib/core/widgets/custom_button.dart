import 'package:flutter/material.dart';
import 'button_variant.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    
    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = theme.primaryColor;
        foregroundColor = Colors.white;
        borderColor = theme.primaryColor;
        break;
      case ButtonVariant.secondary:
        backgroundColor = theme.colorScheme.secondaryContainer;
        foregroundColor = theme.colorScheme.onSecondaryContainer;
        borderColor = theme.colorScheme.secondaryContainer;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.primaryColor;
        borderColor = theme.primaryColor;
        break;
    }
    
    final button = SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
    
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    
    return button;
  }
}