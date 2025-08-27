import 'package:flutter/material.dart';

/// Material Design 3準拠の撮影ボタンウィジェット
/// FloatingActionButtonを基にした大きなカメラボタン
class MaterialCaptureButton extends StatelessWidget {
  const MaterialCaptureButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 96,
      height: 96,
      child: FloatingActionButton.large(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        backgroundColor: isEnabled 
            ? theme.floatingActionButtonTheme.backgroundColor
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: isEnabled 
            ? theme.floatingActionButtonTheme.foregroundColor
            : theme.colorScheme.onSurface,
        elevation: theme.floatingActionButtonTheme.elevation,
        focusElevation: theme.floatingActionButtonTheme.focusElevation,
        hoverElevation: theme.floatingActionButtonTheme.hoverElevation,
        highlightElevation: theme.floatingActionButtonTheme.highlightElevation,
        disabledElevation: 0,
        shape: theme.floatingActionButtonTheme.shape,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.floatingActionButtonTheme.foregroundColor 
                          ?? theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                )
              : Icon(
                  Icons.photo_camera,
                  size: 36,
                  color: theme.floatingActionButtonTheme.foregroundColor
                      ?? theme.colorScheme.onPrimaryContainer,
                ),
        ),
      ),
    );
  }
}