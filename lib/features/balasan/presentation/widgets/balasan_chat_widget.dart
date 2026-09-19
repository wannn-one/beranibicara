import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/balasan/presentation/providers/balasan_notifier.dart';
import 'package:beranibicara/features/balasan/presentation/widgets/balasan_bubble_widget.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

/// Widget to display chat/conversation for a report
/// 
/// Shows all replies (balasan) with real-time updates
/// Only TPPK can send messages (enforced by UI + RLS)
class BalasanChatWidget extends StatefulWidget {
  final int reportId;

  const BalasanChatWidget({
    super.key,
    required this.reportId,
  });

  @override
  State<BalasanChatWidget> createState() => _BalasanChatWidgetState();
}

class _BalasanChatWidgetState extends State<BalasanChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  BalasanNotifier? _balasanNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _balasanNotifier ??= context.read<BalasanNotifier>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _balasanNotifier?.watchBalasan(widget.reportId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _balasanNotifier?.stopWatching();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final authNotifier = context.read<AuthNotifier>();
    final balasanNotifier = context.read<BalasanNotifier>();

    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final user = authNotifier.user;
    if (user == null) {
      _showError('User tidak ditemukan');
      return;
    }

    // Check if user is TPPK
    if (user.role.toString().split('.').last != 'tppk') {
      _showError('Hanya TPPK yang dapat mengirim balasan');
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    final success = await balasanNotifier.createBalasan(
      reportId: widget.reportId,
      authorId: user.id,
      pesan: message,
    );

    if (success) {
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else if (balasanNotifier.errorMessage != null) {
      _showError(balasanNotifier.errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _confirmDelete(int balasanId) async {
    final confirmed = await showConfirmDialog(
      context,
      'Hapus Balasan',
      'Apakah Anda yakin ingin menghapus balasan ini?',
      confirmText: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    final authNotifier = context.read<AuthNotifier>();
    final balasanNotifier = context.read<BalasanNotifier>();
    final user = authNotifier.user;
    if (user == null) return;

    final success = await balasanNotifier.deleteBalasan(
      balasanId: balasanId,
      userId: user.id,
    );

    if (!success && balasanNotifier.errorMessage != null) {
      _showError(balasanNotifier.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final balasanNotifier = context.watch<BalasanNotifier>();
    final user = authNotifier.user;

    // Check if user is TPPK to show input field
    final isTppk = user?.role.toString().split('.').last == 'tppk';

    return Column(
      children: [
        // Chat messages list
        Expanded(
          child: _buildMessagesList(balasanNotifier, user?.id),
        ),

        // Input field (only for TPPK)
        if (isTppk) _buildInputField(balasanNotifier),
      ],
    );
  }

  Widget _buildMessagesList(BalasanNotifier notifier, String? currentUserId) {
    if (notifier.status == BalasanStatus.loading && notifier.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.status == BalasanStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              notifier.errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<BalasanNotifier>().watchBalasan(widget.reportId);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (notifier.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada balasan.\nTPPK akan menanggapi laporan Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Auto-scroll when new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToBottom();
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifier.balasanList.length,
      itemBuilder: (context, index) {
        final balasan = notifier.balasanList[index];
        return BalasanBubbleWidget(
          balasan: balasan,
          currentUserId: currentUserId ?? '',
          onLongPress: () => _confirmDelete(balasan.id),
        );
      },
    );
  }

  Widget _buildInputField(BalasanNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Tulis balasan...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: notifier.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: notifier.isSending ? null : _sendMessage,
                  ),
          ),
        ],
      ),
    );
  }
}
