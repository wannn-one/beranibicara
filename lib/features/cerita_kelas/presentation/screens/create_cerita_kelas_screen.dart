import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/providers/cerita_kelas_notifier.dart';

class CreateCeritaKelasScreen extends StatefulWidget {
  const CreateCeritaKelasScreen({super.key});

  @override
  State<CreateCeritaKelasScreen> createState() =>
      _CreateCeritaKelasScreenState();
}

class _CreateCeritaKelasScreenState extends State<CreateCeritaKelasScreen> {
  final _judulController = TextEditingController();
  final _kontenController = TextEditingController();
  PlatformFile? _imageFile;
  int? _kelasId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final user = context.read<AuthNotifier>().user;
      if (user == null) return;
      if (user.isSiswa) {
        setState(() => _kelasId = user.kelasId);
        return;
      }
      if (user.isGuru) {
        final notifier = context.read<CeritaKelasNotifier>();
        if (notifier.waliKelas.isEmpty) {
          await notifier.loadWaliKelas(user.id);
        }
        if (!mounted) return;
        setState(() {
          if (notifier.waliKelas.length == 1) {
            _kelasId = notifier.waliKelas.first.id;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    super.dispose();
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
      setState(() => _imageFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.red),
      );
    }
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
    final user = context.read<AuthNotifier>().user;
    if (user == null) return;
    if (_kelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kelas tujuan cerita'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final imagePath = await _resolveImagePath();
    if (!mounted) return;
    final notifier = context.read<CeritaKelasNotifier>();
    final success = await notifier.create(
      authorId: user.id,
      kelasId: _kelasId!,
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
    final user = context.watch<AuthNotifier>().user;
    final saving = notifier.isSaving;
    final waliOptions = notifier.waliKelas;

    return Scaffold(
      appBar: AppBar(title: const Text('Tulis Cerita Kelas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user?.isGuru == true && waliOptions.length > 1) ...[
            DropdownButtonFormField<int>(
              initialValue: _kelasId,
              decoration: const InputDecoration(
                labelText: 'Kelas',
                border: OutlineInputBorder(),
              ),
              items: waliOptions
                  .map(
                    (k) => DropdownMenuItem(value: k.id, child: Text(k.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _kelasId = value),
            ),
            const SizedBox(height: 12),
          ],
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
          const Text('Gambar (opsional)'),
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
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Tanpa gambar')),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: saving ? null : _pickImage,
            icon: const Icon(Icons.image),
            label: Text(_imageFile == null ? 'Pilih gambar' : 'Ganti gambar'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Terbitkan'),
          ),
        ],
      ),
    );
  }
}
