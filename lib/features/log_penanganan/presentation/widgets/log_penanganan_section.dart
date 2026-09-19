import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/log_penanganan/presentation/providers/log_penanganan_notifier.dart';

class LogPenangananSection extends StatefulWidget {
  final int reportId;

  const LogPenangananSection({super.key, required this.reportId});

  @override
  State<LogPenangananSection> createState() => _LogPenangananSectionState();
}

class _LogPenangananSectionState extends State<LogPenangananSection> {
  final _catatanController = TextEditingController();
  TahapanType _selectedTahapan = TahapanType.penerimaan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LogPenangananNotifier>().load(widget.reportId);
      }
    });
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthNotifier>().user;
    if (user == null) return;

    final notifier = context.read<LogPenangananNotifier>();
    final success = await notifier.addLog(
      reportId: widget.reportId,
      authorId: user.id,
      catatan: _catatanController.text,
      tahapan: _selectedTahapan,
    );

    if (!mounted) return;
    if (success) {
      _catatanController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log penanganan ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.errorMessage ?? 'Gagal menambah log'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final notifier = context.watch<LogPenangananNotifier>();
    final canWrite =
        user?.role == UserRole.tppk || user?.role == UserRole.admin;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline),
                const SizedBox(width: 8),
                Text(
                  'Log Penanganan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notifier.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (notifier.logs.isEmpty)
              Text(
                'Belum ada catatan penanganan',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...notifier.logs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.tahapan.label,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(log.catatan),
                            const SizedBox(height: 4),
                            Text(
                              '${log.authorName ?? 'TPPK'} · ${formatAppDateTime(log.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (canWrite) ...[
              const Divider(height: 24),
              DropdownButtonFormField<TahapanType>(
                initialValue: _selectedTahapan,
                decoration: const InputDecoration(
                  labelText: 'Tahapan',
                  border: OutlineInputBorder(),
                ),
                items: TahapanType.values
                    .map(
                      (tahapan) => DropdownMenuItem(
                        value: tahapan,
                        child: Text(tahapan.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTahapan = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _catatanController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Minimal 10 karakter',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: notifier.isSaving ? null : _submit,
                  child: notifier.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tambah Log'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
