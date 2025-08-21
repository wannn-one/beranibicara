import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/screens/dashboard_student.dart';

final supabase = Supabase.instance.client;

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _kelasList = [];

  int? _selectedTingkat;
  String? _selectedJurusan;
  int? _finalKelasId;

  List<int> _tingkatOptions = [];
  List<String> _jurusanOptions = [];

  @override
  void initState() {
    super.initState();
    _getKelasList();
  }

  Future<void> _getKelasList() async {
    try {
      final response = await supabase.from('kelas').select('id, tingkat, jurusan');
      final List<Map<String, dynamic>> loadedKelas = (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      setState(() {
        _kelasList = loadedKelas;
        _tingkatOptions = loadedKelas.map<int>((k) => k['tingkat']).toSet().toList()..sort();
      });

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar kelas')),
        );
      }
    }
  }

    void _onTingkatChanged(int? newTingkat) {
    setState(() {
      _selectedTingkat = newTingkat;
      // Kosongkan pilihan jurusan sebelumnya
      _selectedJurusan = null;
      _finalKelasId = null;

      if (newTingkat != null) {
        // Filter jurusan yang tersedia untuk tingkat yang dipilih
        _jurusanOptions = _kelasList
            .where((k) => k['tingkat'] == newTingkat)
            .map<String>((k) => k['jurusan'])
            .toSet()
            .toList()..sort();
      } else {
        _jurusanOptions = [];
      }
    });
  }

  void _onJurusanChanged(String? newJurusan) {
    setState(() {
      _selectedJurusan = newJurusan;
      if (_selectedTingkat != null && newJurusan != null) {
        // Cari ID kelas yang cocok dengan kombinasi tingkat dan jurusan
        final selectedKelas = _kelasList.firstWhere(
            (k) => k['tingkat'] == _selectedTingkat && k['jurusan'] == newJurusan);
        _finalKelasId = selectedKelas['id'];
      } else {
        _finalKelasId = null;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_finalKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tingkat dan jurusan Anda')),
      );
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').update({'kelas_id': _finalKelasId}).eq('id', userId);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan profil')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil Anda')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pilih Kelas Anda',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Dropdown 1: Tingkat
            DropdownButtonFormField<int>(
              initialValue: _selectedTingkat,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              hint: const Text('Pilih Tingkat'),
              items: _tingkatOptions.map((tingkat) {
                return DropdownMenuItem<int>(
                  value: tingkat,
                  child: Text('Kelas $tingkat'),
                );
              }).toList(),
              onChanged: _onTingkatChanged,
            ),
            
            const SizedBox(height: 16),

            // Dropdown 2: Jurusan
            DropdownButtonFormField<String>(
              initialValue: _selectedJurusan,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              hint: const Text('Pilih Jurusan'),
              // Items akan kosong jika tingkat belum dipilih
              items: _jurusanOptions.map((jurusan) {
                return DropdownMenuItem<String>(
                  value: jurusan,
                  child: Text('Jurusan $jurusan'),
                );
              }).toList(),
              // Nonaktifkan dropdown ini jika tingkat belum dipilih
              onChanged: _selectedTingkat == null ? null : _onJurusanChanged,
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan & Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}