import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/widgets/student_drawer.dart';

final supabase = Supabase.instance.client;

class CreateReportScreen extends StatefulWidget {
  static const String routeName = '/create-report';
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isAnonymous = false;
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul laporan minimal 3 karakter.')),
      );
      return;
    }
    
    if (_descriptionController.text.trim().length <= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi kejadian minimal 10 karakter.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      List<String> imageUrls = [];
      final userId = supabase.auth.currentUser!.id;

      // 1. Upload semua gambar yang dipilih SECARA BERSAMAAN (PARALEL)
      if (_selectedImages.isNotEmpty) {
        final List<String> filePaths = [];
        final uploadFutures = _selectedImages.map((image) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(image)}.jpg';
          final filePath = '$userId/$fileName';
          filePaths.add(filePath); // Simpan path untuk nanti
          return supabase.storage.from('evidence').upload(filePath, image);
        }).toList();

        // Tunggu semua proses upload selesai
        await Future.wait(uploadFutures);

        // Ambil semua URL publik dari path yang sudah disimpan
        imageUrls = filePaths.map((filePath) {
          return supabase.storage.from('evidence').getPublicUrl(filePath);
        }).toList();
      }

      // 2. Insert data laporan utama
      final newReport = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'is_anonymous': _isAnonymous,
        'reporter_id': userId, // Selalu pakai userId, tidak pernah null
      };
      final insertedReport = await supabase.from('reports').insert(newReport).select().single();

      // 3. Jika ada gambar, insert SEMUA link bukti DALAM SATU PANGGILAN
      if (imageUrls.isNotEmpty) {
        final evidenceMaps = imageUrls.map((url) => {
          'report_id': insertedReport['id'],
          'file_url': url,
          'file_type': 'image/jpeg',
        }).toList();
        await supabase.from('evidence').insert(evidenceMaps);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dikirim!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim laporan: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
}

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const StudentDrawer(currentRoute: CreateReportScreen.routeName),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Judul Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Berikan judul singkat untuk laporan ini...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Deskripsikan Kejadian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Ceritakan apa yang terjadi, siapa yang terlibat, kapan, dan di mana...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Unggah Bukti (Opsional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_selectedImages.isEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('Belum ada bukti dipilih')),
              )
            else
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              width: 120,
                              height: 150,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickImages,
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFF36A395),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(_selectedImages.isEmpty 
                        ? 'Pilih Gambar dari Galeri' 
                        : 'Tambah Gambar Lagi'),
                  ),
                ),
                if (_selectedImages.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImages.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Hapus Semua'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Laporkan secara Anonim', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Identitas Anda tidak akan disertakan dalam laporan.'),
              value: _isAnonymous,
              activeThumbColor: Color(0xFF36A395),
              onChanged: (bool value) {
                setState(() { _isAnonymous = value; });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: const Color(0xFF36A395),
                foregroundColor: Colors.white,
              ),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Kirim Laporan'),
            ),
          ],
        ),
      ),
    );
  }
}