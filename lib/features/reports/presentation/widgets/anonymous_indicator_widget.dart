import 'package:flutter/material.dart';

/// Anonymous Indicator Widget - shows if a report is anonymous
class AnonymousIndicatorWidget extends StatelessWidget {
  final bool isAnonymous;
  final double? size;
  final Color? color;

  const AnonymousIndicatorWidget({
    super.key,
    required this.isAnonymous,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAnonymous) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off,
            size: size ?? 14,
            color: color ?? Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Anonim',
            style: TextStyle(
              fontSize: (size ?? 14) - 2,
              color: color ?? Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
