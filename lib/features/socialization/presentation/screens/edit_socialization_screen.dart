import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';
import 'package:beranibicara/features/socialization/presentation/providers/socialization_notifier.dart';

class EditSocializationScreen extends StatefulWidget {
  final int articleId;

  const EditSocializationScreen({super.key, required this.articleId});

  @override
  State<EditSocializationScreen> createState() => _EditSocializationScreenState();
}

class _EditSocializationScreenState extends State<EditSocializationScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  PlatformFile? _imageFile;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<SocializationNotifier>();
      final current = notifier.current;
      if (current != null && current.id == widget.articleId) {
        _fill(current);
      } else {
        notifier.loadById(widget.articleId);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _fill(Socialization item) {
    if (_filled) return;
    _filled = true;
    _titleController.text = item.title;
    _contentController.text = item.content;
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > AppConstants.maxFileSize) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar maksimal 10MB'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _imageFile = file;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _resolveImagePath() async {
    final file = _imageFile;
    if (file == null) return null;
    if (file.path != null && file.path!.isNotEmpty) {
      return file.path;
    }
    if (file.bytes == null) return null;
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${file.name}');
    await tempFile.writeAsBytes(file.bytes!);
    return tempFile.path;
  }

  Future<void> _save() async {
    String? imagePath;
    if (_imageFile != null) {
      imagePath = await _resolveImagePath();
      if (!mounted) return;
      if (imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar tidak bisa dibaca'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final notifier = context.read<SocializationNotifier>();
    final success = await notifier.update(
      id: widget.articleId,
      title: _titleController.text,
      content: _contentController.text,
      imagePath: imagePath,
    );
    if (!mounted) return;
    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.errorMessage ?? 'Gagal menyimpan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SocializationNotifier>();
    final item = notifier.current;
    if (item != null && item.id == widget.articleId) {
      _fill(item);
    }
    final saving = notifier.isSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Sosialisasi')),
      body: notifier.isLoading && !_filled
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Isi',
                    hintText:
                        'Tulis tautan dengan https:// agar bisa diketuk',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Gambar'),
                const SizedBox(height: 8),
                if (_imageFile?.path != null && _imageFile!.path!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imageFile!.path!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (item?.coverImageUrl != null &&
                    item!.coverImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.coverImageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('Belum ada gambar')),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: saving ? null : _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Ganti gambar'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _save,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
    );
  }
}
