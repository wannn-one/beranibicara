import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';
import 'package:beranibicara/shared/widgets/linkable_text.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/socialization/presentation/providers/socialization_notifier.dart';

class SocializationDetailScreen extends StatefulWidget {
  final int articleId;

  const SocializationDetailScreen({super.key, required this.articleId});

  @override
  State<SocializationDetailScreen> createState() =>
      _SocializationDetailScreenState();
}

class _SocializationDetailScreenState extends State<SocializationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SocializationNotifier>().loadById(widget.articleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SocializationNotifier>();
    final item = notifier.current;
    final role = context.watch<AuthNotifier>().user?.role;
    final canEdit = role == UserRole.tppk || role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sosialisasi'),
        actions: [
          if (canEdit && item != null && item.id == widget.articleId) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.push('/socialization/${widget.articleId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: notifier.isSaving
                  ? null
                  : () => _confirmDelete(context, widget.articleId),
            ),
          ],
        ],
      ),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? Center(child: Text(notifier.errorMessage ?? 'Tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.coverImageUrl != null &&
                          item.coverImageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.coverImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.authorName ?? 'TPPK'} · ${formatAppDateTime(item.publishedAt ?? item.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
                      LinkableText(
                        item.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final confirmed = await showConfirmDialog(
      context,
      'Hapus sosialisasi?',
      'Artikel tidak akan tampil lagi. Tindakan ini memakai soft delete.',
      confirmText: 'Hapus',
    );
    if (confirmed != true || !context.mounted) return;

    final notifier = context.read<SocializationNotifier>();
    final success = await notifier.delete(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Artikel dihapus'
              : (notifier.errorMessage ?? 'Gagal menghapus'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) context.pop();
  }
}
