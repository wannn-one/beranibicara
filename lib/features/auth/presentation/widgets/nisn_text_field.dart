import 'package:flutter/material.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/core/constants/app_strings.dart';

/// NISN Text Field with Verification Support
class NisnTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onVerifyPressed;
  final bool isVerifying;
  final bool? isVerified;
  final String? errorText;
  final bool enabled;
  final String labelText;

  const NisnTextField({
    super.key,
    required this.controller,
    this.onVerifyPressed,
    this.isVerifying = false,
    this.isVerified,
    this.errorText,
    this.enabled = true,
    this.labelText = AppStrings.nisnRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled && !isVerifying,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: AppStrings.nisnHint,
                  errorText: errorText,
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  prefixIcon: const Icon(Icons.badge),
                  suffixIcon: isVerified != null
                      ? Icon(
                          isVerified! ? Icons.check_circle : Icons.error,
                          color: isVerified!
                              ? AppColors.success
                              : AppColors.error,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryDark,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (onVerifyPressed != null) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    (enabled && !isVerifying && controller.text.length == 10)
                    ? onVerifyPressed
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ],
          ],
        ),
        if (isVerifying)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppStrings.nisnVerifying,
              style: TextStyle(fontSize: 12, color: AppColors.info),
            ),
          ),
        if (isVerified == true)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppStrings.nisnValid,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
