import 'package:flutter/material.dart';

/// 撮影ボタンウィジェット
class CaptureButton extends StatelessWidget {
  const CaptureButton({
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
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled && !isLoading ? onPressed : null,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? Colors.white : Colors.grey,
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey,
                        ),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.camera_alt,
                    color: Colors.grey,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}