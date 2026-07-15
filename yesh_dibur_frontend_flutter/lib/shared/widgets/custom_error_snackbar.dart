import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomErrorSnackbar {
  static void show(
    BuildContext context, 
    String message, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: 'נסה שוב',
                textColor: AppColors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  // פונקציה מקבילה להודעות הצלחה (למשל: "הפוסט פורסם בהצלחה")
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}