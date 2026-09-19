import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/providers/cerita_kelas_notifier.dart';

class EditCeritaKelasScreen extends StatefulWidget {
  final int ceritaId;

  const EditCeritaKelasScreen({super.key, required this.ceritaId});

  @override
  State<EditCeritaKelasScreen> createState() => _EditCeritaKelasScreenState();
}

class _EditCeritaKelasScreenState extends State<EditCeritaKelasScreen> {
  final _judulController = TextEditingController();
  final _kontenController = TextEditingController();
  PlatformFile? _imageFile;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<CeritaKelasNotifier>();
      final current = notifier.current;
      if (current != null && current.id == widget.ceritaId) {
        _fill(current);
      } else {
        notifier.loadById(widget.ceritaId);
      }
    });
  }

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    super.dispose();
  }

  void _fill(CeritaKelas item) {
    if (_filled) return;
    _filled = true;
    _judulController.text = item.judul;
    _kontenController.text = item.konten;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > AppConstants.maxFileSize) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar maksimal 10MB'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _imageFile = file);
  }

  Future<String?> _resolveImagePath() async {
    final file = _imageFile;
    if (file == null) return null;
    if (file.path != null && file.path!.isNotEmpty) return file.path;
    if (file.bytes == null) return null;
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${file.name}');
    await tempFile.writeAsBytes(file.bytes!);
    return tempFile.path;
  }

  Future<void> _save() async {
    final imagePath = await _resolveImagePath();
    if (!mounted) return;
    final notifier = context.read<CeritaKelasNotifier>();
    final success = await notifier.update(
      id: widget.ceritaId,
      judul: _judulController.text,
      konten: _kontenController.text,
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
    final notifier = context.watch<CeritaKelasNotifier>();
    final current = notifier.current;
    if (current != null && current.id == widget.ceritaId) {
      _fill(current);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Cerita')),
      body: notifier.isLoading && !_filled
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kontenController,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Isi cerita',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: notifier.isSaving ? null : _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_imageFile == null ? 'Ganti gambar' : 'Gambar dipilih'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: notifier.isSaving ? null : _save,
                  child: notifier.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
    );
  }
}
