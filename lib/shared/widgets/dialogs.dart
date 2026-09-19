import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:beranibicara/core/constants/app_colors.dart';

void showAppMessageDialog(
  BuildContext context,
  String title,
  String message,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void showErrorDialog(BuildContext context, String message) {
  showAppMessageDialog(context, 'Error', message);
}

void showSuccessDialog(
  BuildContext context,
  String message, {
  VoidCallback? onClose,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success),
          SizedBox(width: 8),
          Text('Berhasil'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onClose?.call();
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context,
  String title,
  String message, {
  String cancelText = 'Batal',
  String confirmText = 'Ya',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );

  return result ?? false;
}

void showLoadingDialog(BuildContext context, {String? message}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'loading',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (dialogContext, _, __) {
      return PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.white),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void hideLoadingDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}
