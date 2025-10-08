import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

final supabase = Supabase.instance.client;

class BuatCeritaAdminScreen extends StatefulWidget {
  const BuatCeritaAdminScreen({super.key});

  @override
  State<BuatCeritaAdminScreen> createState() => _BuatCeritaAdminScreenState();
}

class _BuatCeritaAdminScreenState extends State<BuatCeritaAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _kontenController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _kelasList = [];
  int? _selectedKelasId;
  bool _isLoadingKelas = true;

  @override
  void initState() {
    super.initState();
    _fetchKelas();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    super.dispose();
  }

  Future<void> _fetchKelas() async {
    try {
      final response = await supabase
          .from('kelas')
          .select('id, tingkat, jurusan')
          .neq('tingkat', 99)
          .neq('jurusan', 'X')
          .order('tingkat', ascending: true)
          .order('jurusan', ascending: true);
      
      setState(() {
        _kelasList = (response as List).map((item) => item as Map<String, dynamic>).toList();
        _isLoadingKelas = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _isLoadingKelas = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data kelas: $error')),
        );
      }
    }
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

  Future<void> _submitCerita({bool publish = false}) async {
    if (!_formKey.currentState!.validate() || _selectedKelasId == null) {
      if (_selectedKelasId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih kelas terlebih dahulu')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      String? imageUrl;

      // Upload gambar jika ada
      if (_selectedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'cerita_$timestamp.jpg';
        
        await supabase.storage
            .from('cerita-images')
            .upload(fileName, _selectedImage!);

        imageUrl = supabase.storage
            .from('cerita-images')
            .getPublicUrl(fileName);
      }

      // Insert cerita ke database
      await supabase.from('cerita_kelas').insert({
        'judul': _judulController.text.trim(),
        'konten': _kontenController.text.trim(),
        'author_id': userId,
        'kelas_id': _selectedKelasId!,
        'gambar_url': imageUrl,
        'is_published': publish,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish 
              ? 'Cerita berhasil dibuat dan dipublikasikan!' 
              : 'Cerita berhasil disimpan sebagai draft!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan cerita: $error')),
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
        title: const Text('Buat Cerita'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingKelas
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pilih Kelas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, color: Color(0xFF36A395)),
                              const SizedBox(width: 8),
                              const Text(
                                'Pilih Kelas',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedKelasId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Pilih kelas untuk cerita',
                            ),
                            items: _kelasList.map((kelas) => DropdownMenuItem<int>(
                              value: kelas['id'],
                              child: Text('${kelas['tingkat']}${kelas['jurusan']}'),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedKelasId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Silakan pilih kelas';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Form Cerita
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit, color: Color(0xFF36A395)),
                              const SizedBox(width: 8),
                              const Text(
                                'Tulis Cerita',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Judul
                          TextFormField(
                            controller: _judulController,
                            decoration: const InputDecoration(
                              labelText: 'Judul Cerita',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Judul tidak boleh kosong';
                              }
                              if (value.trim().length < 3) {
                                return 'Judul minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Konten
                          TextFormField(
                            controller: _kontenController,
                            decoration: const InputDecoration(
                              labelText: 'Isi Cerita',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 8,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Isi cerita tidak boleh kosong';
                              }
                              if (value.trim().length < 10) {
                                return 'Isi cerita minimal 10 karakter';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Gambar
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.image, color: Color(0xFF36A395)),
                              const SizedBox(width: 8),
                              const Text(
                                'Gambar Cerita (Opsional)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (_selectedImage != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Ganti Gambar'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: _pickImage,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, 
                                         size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text('Ketuk untuk menambah gambar',
                                         style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tombol Submit
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _submitCerita(publish: false),
                          icon: const Icon(Icons.save),
                          label: const Text('Simpan Draft'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _submitCerita(publish: true),
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.publish),
                          label: const Text('Publikasikan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF36A395),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
