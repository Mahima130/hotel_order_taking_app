import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? cancelText;
  final String confirmText;
  final VoidCallback onConfirm;
  final Color? confirmColor;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.cancelText,
    this.confirmText = AppStrings.ok,
    this.confirmColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // ✅ ADD THIS LINE - Fixes pink shade!
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.bold)),
      content: Text(content, style: const TextStyle(fontSize: AppSizes.fontM)),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText!, style: TextStyle(color: Colors.grey[600])),
          ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.error,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium)),
          ),
          child: Text(confirmText,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
