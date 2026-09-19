import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';
import 'package:beranibicara/shared/widgets/linkable_text.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/providers/cerita_kelas_notifier.dart';

class CeritaKelasDetailScreen extends StatefulWidget {
  final int ceritaId;

  const CeritaKelasDetailScreen({super.key, required this.ceritaId});

  @override
  State<CeritaKelasDetailScreen> createState() =>
      _CeritaKelasDetailScreenState();
}

class _CeritaKelasDetailScreenState extends State<CeritaKelasDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CeritaKelasNotifier>().loadById(widget.ceritaId);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      'Hapus cerita?',
      'Cerita tidak akan tampil lagi di kelas.',
      confirmText: 'Hapus',
    );
    if (confirmed != true || !mounted) return;
    final notifier = context.read<CeritaKelasNotifier>();
    final success = await notifier.delete(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Cerita dihapus' : (notifier.errorMessage ?? 'Gagal'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) context.pop();
  }

  Future<void> _sendComment() async {
    final user = context.read<AuthNotifier>().user;
    if (user == null) return;
    final notifier = context.read<CeritaKelasNotifier>();
    final success = await notifier.addComment(
      ceritaId: widget.ceritaId,
      authorId: user.id,
      tanggapan: _commentController.text,
    );
    if (!mounted) return;
    if (success) {
      _commentController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.errorMessage ?? 'Gagal mengirim'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CeritaKelasNotifier>();
    final user = context.watch<AuthNotifier>().user;
    final item = notifier.current;
    final canManage = item != null &&
        user != null &&
        (item.authorId == user.id ||
            user.role == UserRole.tppk ||
            user.role == UserRole.admin ||
            user.role == UserRole.guru);
    final canDelete = item != null &&
        user != null &&
        (item.authorId == user.id ||
            user.role == UserRole.tppk ||
            user.role == UserRole.admin);
    final canComment = user?.isSiswa == true || user?.isGuru == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerita Kelas'),
        actions: [
          if (item != null && canManage && item.id == widget.ceritaId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.push('/cerita-kelas/${widget.ceritaId}/edit'),
            ),
          if (item != null && canDelete && item.id == widget.ceritaId)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: notifier.isSaving
                  ? null
                  : () => _confirmDelete(widget.ceritaId),
            ),
        ],
      ),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? Center(child: Text(notifier.errorMessage ?? 'Tidak ditemukan'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (item.gambarUrl != null &&
                              item.gambarUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.gambarUrl!,
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
                            item.judul,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.authorName ?? 'Teman sekelas'} · ${formatAppDateTime(item.createdAt)}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 16),
                          LinkableText(
                            item.konten,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tanggapan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (notifier.comments.isEmpty)
                            Text(
                              'Belum ada tanggapan',
                              style: TextStyle(color: Colors.grey.shade600),
                            )
                          else
                            ...notifier.comments.map(
                              (comment) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(comment.authorName ?? 'Teman sekelas'),
                                subtitle: Text(comment.tanggapan),
                                trailing: user != null &&
                                        (comment.authorId == user.id ||
                                            user.role == UserRole.tppk ||
                                            user.role == UserRole.admin)
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => notifier
                                            .deleteComment(comment.id),
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canComment)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    hintText: 'Tulis tanggapan...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed:
                                    notifier.isSaving ? null : _sendComment,
                                icon: const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
