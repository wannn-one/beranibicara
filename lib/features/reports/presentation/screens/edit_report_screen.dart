import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:path_provider/path_provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/features/reports/presentation/widgets/file_preview_widget.dart';

class EditReportScreen extends StatefulWidget {
  final String reportId;

  const EditReportScreen({super.key, required this.reportId});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isAnonymous = false;
  final List<picker.PlatformFile> _newFiles = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _formReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    final reportNotifier = context.read<ReportNotifier>();
    await reportNotifier.getReportById(widget.reportId);
    if (!mounted) return;

    final report = reportNotifier.currentReport;
    if (report == null || !report.isEditable) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _titleController.text = report.title ?? '';
    _descriptionController.text = report.description;
    _isAnonymous = report.isAnonymous;
    setState(() {
      _isLoading = false;
      _formReady = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _totalFileCount(ReportNotifier reportNotifier) {
    return reportNotifier.currentReportEvidence.length + _newFiles.length;
  }

  Future<void> _pickFiles() async {
    final reportNotifier = context.read<ReportNotifier>();
    try {
      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final totalFiles = _totalFileCount(reportNotifier) + result.files.length;
      if (totalFiles > AppConstants.maxFilesPerReport) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maksimal ${AppConstants.maxFilesPerReport} file lampiran',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      for (final file in result.files) {
        if (file.size > AppConstants.maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File ${file.name} terlalu besar. Maksimal 10MB per file.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _newFiles.addAll(result.files);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<String>> _resolveFilePaths() async {
    final paths = <String>[];
    final tempDir = await getTemporaryDirectory();

    for (final file in _newFiles) {
      if (file.path != null && file.path!.isNotEmpty) {
        paths.add(file.path!);
        continue;
      }
      if (file.bytes != null) {
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(file.bytes!);
        paths.add(tempFile.path);
      }
    }
    return paths;
  }

  Future<void> _removeExisting(Evidence attachment) async {
    final reportNotifier = context.read<ReportNotifier>();
    final success = await reportNotifier.deleteAttachment(attachment.id);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reportNotifier.errorMessage ?? 'Gagal menghapus lampiran',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final reportNotifier = context.read<ReportNotifier>();
      final success = await reportNotifier.updateReport(
        reportId: widget.reportId,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reportNotifier.errorMessage ?? 'Gagal menyimpan laporan',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_newFiles.isNotEmpty) {
        final paths = await _resolveFilePaths();
        if (paths.isNotEmpty) {
          final uploaded = await reportNotifier.uploadEvidence(
            reportId: widget.reportId,
            filePaths: paths,
          );
          if (!mounted) return;
          if (!uploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  reportNotifier.errorMessage ??
                      'Teks tersimpan, unggah lampiran gagal',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            context.pop();
            return;
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportNotifier = context.watch<ReportNotifier>();
    final user = context.watch<AuthNotifier>().user;
    final report = reportNotifier.currentReport;
    final attachments = reportNotifier.currentReportEvidence;

    if (_isLoading || reportNotifier.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Laporan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (report == null ||
        !_formReady ||
        user?.id != report.reporterId ||
        !report.isEditable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Laporan')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Laporan tidak bisa diedit. Hanya pelapor yang dapat mengubah laporan berstatus Baru.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final canAddMore = _totalFileCount(reportNotifier) <
        AppConstants.maxFilesPerReport;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Laporan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Laporan (Opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: AppConstants.maxReportTitleLength,
              validator: (value) {
                if (value != null &&
                    value.trim().isNotEmpty &&
                    value.trim().length < AppConstants.minReportTitleLength) {
                  return 'Judul minimal ${AppConstants.minReportTitleLength} karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi Laporan *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: AppConstants.maxReportDescriptionLength,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi harus diisi';
                }
                if (value.trim().length <
                    AppConstants.minReportDescriptionLength) {
                  return 'Deskripsi minimal ${AppConstants.minReportDescriptionLength} karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: CheckboxListTile(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
                title: const Text('Laporan Anonim'),
                subtitle: const Text(
                  'Identitas Anda akan disembunyikan dari TPPK dan guru',
                ),
                secondary: const Icon(Icons.visibility_off),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Lampiran',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_totalFileCount(reportNotifier)}/${AppConstants.maxFilesPerReport}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (attachments.isNotEmpty)
              FilePreviewListWidget(
                evidenceList: attachments,
                showDelete: true,
                onDelete: _removeExisting,
              ),
            if (_newFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _newFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Chip(
                    label: Text(file.name, overflow: TextOverflow.ellipsis),
                    onDeleted: () {
                      setState(() {
                        _newFiles.removeAt(index);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (canAddMore)
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Tambah File'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
