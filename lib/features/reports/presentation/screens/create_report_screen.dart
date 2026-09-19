import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';

/// Create Report Screen - allows students to create new reports
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isAnonymous = false;
  final List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Check max file count
        final totalFiles = _selectedFiles.length + result.files.length;
        if (totalFiles > AppConstants.maxFilesPerReport) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Maksimal ${AppConstants.maxFilesPerReport} file bukti',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Check file sizes
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
          _selectedFiles.addAll(result.files);
        });
      }
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

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authNotifier = context.read<AuthNotifier>();
      final reportNotifier = context.read<ReportNotifier>();
      final userId = authNotifier.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create report
      final success = await reportNotifier.createReport(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isAnonymous: _isAnonymous,
        reporterId: userId,
      );

      if (!mounted) return;

      if (success) {
        final reportId = reportNotifier.currentReport?.id;
        if (reportId != null && _selectedFiles.isNotEmpty) {
          final filePaths = await _resolveFilePaths();
          if (filePaths.isNotEmpty) {
            final uploaded = await reportNotifier.uploadEvidence(
              reportId: reportId,
              filePaths: filePaths,
            );
            if (!mounted) return;
            if (!uploaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    reportNotifier.errorMessage ??
                        'Laporan tersimpan, tetapi unggah bukti gagal',
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
            content: Text('Laporan berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          context.pop();
        }
      } else {
        final errorMessage =
            reportNotifier.errorMessage ?? 'Gagal membuat laporan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<List<String>> _resolveFilePaths() async {
    final paths = <String>[];
    final tempDir = await getTemporaryDirectory();

    for (final file in _selectedFiles) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Baru'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Field (Optional)
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Laporan (Opsional)',
                hintText: 'Masukkan judul laporan',
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

            // Description Field (Required)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi Laporan *',
                hintText: 'Ceritakan kejadian yang ingin kamu laporkan...',
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

            // Anonymous Checkbox
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

            // Evidence Files Section
            _buildFilesSection(),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kirim Laporan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Bukti Pendukung (Opsional)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_selectedFiles.length}/${AppConstants.maxFilesPerReport}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Foto atau video bukti kejadian (Max 3 file, 10MB per file)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        // Selected Files
        if (_selectedFiles.isNotEmpty) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: _selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildFileChip(file, index);
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Add Files Button
        if (_selectedFiles.length < AppConstants.maxFilesPerReport)
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
      ],
    );
  }

  Widget _buildFileChip(PlatformFile file, int index) {
    final sizeInMB = (file.size / (1024 * 1024)).toStringAsFixed(2);
    return Chip(
      avatar: Icon(_getFileIcon(file.extension), size: 20),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '$sizeInMB MB',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
      onDeleted: () => _removeFile(index),
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
        return Icons.videocam;
      default:
        return Icons.attach_file;
    }
  }
}
