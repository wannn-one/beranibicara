import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

final supabase = Supabase.instance.client;

class BuatCeritaScreen extends StatefulWidget {
  final Map<String, dynamic> kelasInfo;
  
  const BuatCeritaScreen({super.key, required this.kelasInfo});

  @override
  State<BuatCeritaScreen> createState() => _BuatCeritaScreenState();
}

class _BuatCeritaScreenState extends State<BuatCeritaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _kontenController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cerita_${userId}_$timestamp.jpg';
      
      await supabase.storage
          .from('cerita-images')
          .upload(fileName, imageFile);
      
      final imageUrl = supabase.storage
          .from('cerita-images')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      // Error uploading image
      return null;
    }
  }

  Future<void> _submitCerita() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String? imageUrl;
      
      // Upload gambar jika ada
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          throw Exception('Gagal mengupload gambar');
        }
      }
      
      // Simpan cerita ke database
      await supabase.from('cerita_kelas').insert({
        'author_id': supabase.auth.currentUser!.id,
        'kelas_id': widget.kelasInfo['id'],
        'judul': _judulController.text.trim(),
        'konten': _kontenController.text.trim(),
        'gambar_url': imageUrl,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cerita berhasil dibagikan!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan cerita: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tulis Cerita - Kelas ${widget.kelasInfo['tingkat']}${widget.kelasInfo['jurusan']}'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Info kelas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF36A395).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF36A395)),
                  const SizedBox(width: 12),
                  Text(
                    'Berbagi cerita untuk kelas ${widget.kelasInfo['tingkat']}${widget.kelasInfo['jurusan']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF36A395),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Form judul
            TextFormField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: 'Judul Cerita',
                hintText: 'Berikan judul yang menarik untuk ceritamu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Judul minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Form konten
            TextFormField(
              controller: _kontenController,
              decoration: const InputDecoration(
                labelText: 'Ceritamu',
                hintText: 'Tulis cerita menarik yang ingin kamu bagikan dengan teman-teman sekelas...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Cerita minimal 10 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Bagian gambar
            const Text(
              'Gambar Pendukung (Opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.edit),
                    label: const Text('Ganti Gambar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus Gambar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ] else ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Ketuk untuk menambahkan gambar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Tombol submit
            ElevatedButton(
              onPressed: _isLoading ? null : _submitCerita,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36A395),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Sedang Membagikan...'),
                      ],
                    )
                  : const Text(
                      'Bagikan Cerita',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 