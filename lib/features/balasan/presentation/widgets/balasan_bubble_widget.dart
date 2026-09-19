import 'package:flutter/material.dart';
import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';
import 'package:beranibicara/core/constants/app_colors.dart';

/// Widget to display a single chat bubble for a reply
/// 
/// Differentiates between TPPK (right side, green) and Student (left side, gray)
class BalasanBubbleWidget extends StatelessWidget {
  final BalasanLaporan balasan;
  final String currentUserId;
  final VoidCallback? onLongPress;

  const BalasanBubbleWidget({
    super.key,
    required this.balasan,
    required this.currentUserId,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = balasan.isAuthor(currentUserId);
    final bool isFromTppk = balasan.isFromTppk;

    return Align(
      alignment: isFromTppk ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isCurrentUser ? onLongPress : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isFromTppk
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isFromTppk ? const Radius.circular(16) : Radius.zero,
              bottomRight: isFromTppk ? Radius.zero : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author name
              Text(
                balasan.authorName ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFromTppk ? AppColors.primary : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              // Message content
              Text(
                balasan.pesan,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // Timestamp
              Text(
                balasan.formattedTime,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
