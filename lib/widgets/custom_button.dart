import 'package:flutter/material.dart';

enum ButtonType { primary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonType type;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = ButtonType.primary,
    this.width = double.infinity,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (type == ButtonType.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        child: Text(text),
      );
    }

    Widget content = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.primary ? Colors.white : theme.colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

    final buttonStyle = type == ButtonType.primary
        ? ElevatedButton.styleFrom(
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          )
        : OutlinedButton.styleFrom(
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          );

    final buttonWidget = type == ButtonType.primary
        ? ElevatedButton(
            style: buttonStyle,
            onPressed: isLoading ? null : onPressed,
            child: content,
          )
        : OutlinedButton(
            style: buttonStyle,
            onPressed: isLoading ? null : onPressed,
            child: content,
          );

    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: buttonWidget,
      );
    }

    return SizedBox(
      height: height,
      child: buttonWidget,
    );
  }
}
