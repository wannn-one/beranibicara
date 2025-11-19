import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/utils/nisn_validator.dart';
import 'package:beranibicara/widgets/admin_drawer.dart';

final supabase = Supabase.instance.client;

class KelolaNISNScreen extends StatefulWidget {
  const KelolaNISNScreen({super.key});

  static const String routeName = '/kelola-nisn';

  @override
  State<KelolaNISNScreen> createState() => _KelolaNISNScreenState();
}

class _KelolaNISNScreenState extends State<KelolaNISNScreen> {
  final _nisnController = TextEditingController();
  final _namaController = TextEditingController();
  final _tingkatController = TextEditingController();
  final _jurusanController = TextEditingController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _nisnList = [];
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, registered, unregistered

  @override
  void initState() {
    super.initState();
    _loadNISNList();
  }

  @override
  void dispose() {
    _nisnController.dispose();
    _namaController.dispose();
    _tingkatController.dispose();
    _jurusanController.dispose();
    super.dispose();
  }

  Future<void> _loadNISNList() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await supabase
          .from('nisn_registry')
          .select('*')
          .order('created_at', ascending: false);
      
      setState(() {
        _nisnList = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      _showErrorDialog('Gagal memuat data NISN: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNISN() async {
    if (_nisnController.text.isEmpty || _namaController.text.isEmpty) {
      _showErrorDialog('NISN dan Nama Siswa harus diisi');
      return;
    }

    // Validasi format NISN
    if (!NISNValidator.isValidFormat(_nisnController.text)) {
      _showErrorDialog('Format NISN tidak valid. NISN harus 10 digit angka.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.rpc('add_nisn_to_registry', params: {
        'nisn_input': _nisnController.text.trim(),
        'nama_siswa_input': _namaController.text.trim(),
        'tingkat_input': _tingkatController.text.isNotEmpty ? int.parse(_tingkatController.text) : null,
        'jurusan_input': _jurusanController.text.trim().isNotEmpty ? _jurusanController.text.trim() : null,
      });

      // Clear form
      _nisnController.clear();
      _namaController.clear();
      _tingkatController.clear();
      _jurusanController.clear();

      // Reload data
      await _loadNISNList();
      
      _showSuccessDialog('NISN berhasil ditambahkan');
    } catch (error) {
      _showErrorDialog('Gagal menambahkan NISN: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        List<Map<String, dynamic>> csvData = _parseCSV(content);
        
        if (csvData.isEmpty) {
          _showErrorDialog('File CSV kosong atau format tidak valid');
          return;
        }

        setState(() => _isLoading = true);

        try {
          final response = await supabase.rpc('bulk_add_nisn', params: {
            'nisn_data': csvData,
          });

          await _loadNISNList();
          
          _showSuccessDialog(
            'Upload berhasil!\n'
            'Berhasil: ${response['success_count']}\n'
            'Gagal: ${response['error_count']}'
          );
        } catch (error) {
          _showErrorDialog('Gagal upload CSV: $error');
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } catch (error) {
      _showErrorDialog('Gagal memilih file: $error');
    }
  }

  List<Map<String, dynamic>> _parseCSV(String content) {
    List<Map<String, dynamic>> data = [];
    List<String> lines = content.split('\n');
    
    // Skip header jika ada
    int startIndex = 0;
    if (lines.isNotEmpty && lines[0].toLowerCase().contains('nisn')) {
      startIndex = 1;
    }

    for (int i = startIndex; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      List<String> fields = line.split(',');
      if (fields.length >= 2) {
        String nisn = fields[0].trim();
        String nama = fields[1].trim();
        
        // Validasi format NISN
        if (NISNValidator.isValidFormat(nisn)) {
          data.add({
            'nisn': nisn,
            'nama_siswa': nama,
            'tingkat': fields.length > 2 ? int.tryParse(fields[2].trim()) : null,
            'jurusan': fields.length > 3 ? fields[3].trim() : null,
          });
        }
      }
    }

    return data;
  }

  Future<void> _deleteNISN(String nisn) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus NISN $nisn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        await supabase
            .from('nisn_registry')
            .delete()
            .eq('nisn', nisn);

        await _loadNISNList();
        _showSuccessDialog('NISN berhasil dihapus');
      } catch (error) {
        _showErrorDialog('Gagal menghapus NISN: $error');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredNISNList {
    return _nisnList.where((nisn) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        String query = _searchQuery.toLowerCase();
        if (!nisn['nisn'].toString().toLowerCase().contains(query) &&
            !nisn['nama_siswa'].toString().toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filter by status
      if (_filterStatus == 'registered' && !nisn['is_registered']) {
        return false;
      }
      if (_filterStatus == 'unregistered' && nisn['is_registered']) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola NISN'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const AdminDrawer(currentRoute: KelolaNISNScreen.routeName),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cari NISN atau Nama',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Filter: '),
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Semua')),
                        DropdownMenuItem(value: 'registered', child: Text('Terdaftar')),
                        DropdownMenuItem(value: 'unregistered', child: Text('Belum Terdaftar')),
                      ],
                      onChanged: (value) {
                        setState(() => _filterStatus = value!);
                      },
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _uploadCSV,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload CSV'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Add NISN Form
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah NISN Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _nisnController,
                          decoration: const InputDecoration(
                            labelText: 'NISN (10 digit)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Siswa',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tingkatController,
                          decoration: const InputDecoration(
                            labelText: 'Tingkat (1-6)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _jurusanController,
                          decoration: const InputDecoration(
                            labelText: 'Jurusan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addNISN,
                      child: _isLoading 
                        ? const CircularProgressIndicator()
                        : const Text('Tambah NISN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // NISN List
          Expanded(
            child: _isLoading && _nisnList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredNISNList.length,
                  itemBuilder: (context, index) {
                    final nisn = _filteredNISNList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(nisn['nisn']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nisn['nama_siswa']),
                            if (nisn['tingkat'] != null) Text('Tingkat: ${nisn['tingkat']}'),
                            if (nisn['jurusan'] != null) Text('Jurusan: ${nisn['jurusan']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                nisn['is_registered'] ? 'Terdaftar' : 'Belum Terdaftar',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: nisn['is_registered'] 
                                ? Colors.green[100] 
                                : Colors.orange[100],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteNISN(nisn['nisn']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
