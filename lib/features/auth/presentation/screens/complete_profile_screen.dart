import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  int? _selectedTingkat;
  String? _selectedJurusan;
  int? _finalKelasId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthNotifier>().loadKelasList();
    });
  }

  Future<void> _saveProfile() async {
    if (_finalKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tingkat dan jurusan Anda')),
      );
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final success = await authNotifier.completeStudentProfile(_finalKelasId!);
    if (!mounted) return;

    if (success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authNotifier.errorMessage ?? 'Gagal menyimpan profil',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final kelasList = authNotifier.kelasList;
    final tingkatOptions =
        kelasList.map((k) => k.tingkat).toSet().toList()..sort();
    final jurusanOptions = _selectedTingkat == null
        ? <String>[]
        : (kelasList
            .where((k) => k.tingkat == _selectedTingkat)
            .map((k) => k.jurusan)
            .toSet()
            .toList()
          ..sort());

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
            const SizedBox(height: 8),
            Text(
              'Hanya siswa yang perlu memilih kelas.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _selectedTingkat,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              hint: Text(
                authNotifier.isLoadingKelas
                    ? 'Memuat kelas...'
                    : 'Pilih Tingkat',
              ),
              items: tingkatOptions
                  .map(
                    (tingkat) => DropdownMenuItem<int>(
                      value: tingkat,
                      child: Text('Kelas $tingkat'),
                    ),
                  )
                  .toList(),
              onChanged: authNotifier.isLoadingKelas
                  ? null
                  : (newTingkat) {
                      setState(() {
                        _selectedTingkat = newTingkat;
                        _selectedJurusan = null;
                        _finalKelasId = null;
                      });
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedTingkat),
              initialValue: _selectedJurusan,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              hint: const Text('Pilih Jurusan'),
              items: jurusanOptions
                  .map(
                    (jurusan) => DropdownMenuItem<String>(
                      value: jurusan,
                      child: Text('Jurusan $jurusan'),
                    ),
                  )
                  .toList(),
              onChanged: (_selectedTingkat == null ||
                      authNotifier.isLoadingKelas)
                  ? null
                  : (newJurusan) {
                      setState(() {
                        _selectedJurusan = newJurusan;
                        if (_selectedTingkat != null && newJurusan != null) {
                          final selected = kelasList.firstWhere(
                            (k) =>
                                k.tingkat == _selectedTingkat &&
                                k.jurusan == newJurusan,
                          );
                          _finalKelasId = selected.id;
                        } else {
                          _finalKelasId = null;
                        }
                      });
                    },
            ),
            if (authNotifier.kelasError != null) ...[
              const SizedBox(height: 12),
              Text(
                authNotifier.kelasError!,
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: () => authNotifier.loadKelasList(force: true),
                child: const Text('Coba lagi'),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: authNotifier.isUpdatingProfile ||
                      authNotifier.isLoadingKelas
                  ? null
                  : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: authNotifier.isUpdatingProfile
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan & Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}
