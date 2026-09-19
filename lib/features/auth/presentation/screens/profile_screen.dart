import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/domain/entities/kelas.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  int? _selectedTingkat;
  String? _selectedJurusan;
  int? _kelasId;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _hydratedKelas = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user;
    _nameController.text = user?.fullName ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthNotifier>();
      if (auth.user?.isSiswa == true) {
        auth.loadKelasList();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _hydrateKelasIfNeeded(AuthNotifier auth) {
    final user = auth.user;
    if (_hydratedKelas || user == null || !user.isSiswa) return;
    if (auth.kelasList.isEmpty) return;
    final kelasId = user.kelasId;
    Kelas? match;
    if (kelasId != null) {
      final found = auth.kelasList.where((k) => k.id == kelasId);
      if (found.isNotEmpty) match = found.first;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hydratedKelas) return;
      setState(() {
        _hydratedKelas = true;
        if (match != null) {
          _selectedTingkat = match.tingkat;
          _selectedJurusan = match.jurusan;
          _kelasId = match.id;
        }
      });
    });
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.siswa:
        return 'Siswa';
      case UserRole.guru:
        return 'Guru';
      case UserRole.tppk:
        return 'TPPK';
      case UserRole.admin:
        return 'Admin';
    }
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthNotifier>();
    final user = auth.user;
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Nama tidak boleh kosong', isError: true);
      return;
    }

    String? fullName;
    int? kelasId;
    if (name != (user.fullName ?? '').trim()) {
      fullName = name;
    }
    if (user.isSiswa) {
      if (_kelasId == null) {
        _showMessage('Pilih kelas Anda', isError: true);
        return;
      }
      if (_kelasId != user.kelasId) {
        kelasId = _kelasId;
      }
    }

    if (fullName == null && kelasId == null) {
      _showMessage('Tidak ada perubahan profil');
      return;
    }

    final success = await auth.updateProfile(
      fullName: fullName,
      kelasId: kelasId,
    );
    if (!mounted) return;
    _showMessage(
      success ? 'Profil disimpan' : (auth.errorMessage ?? 'Gagal menyimpan'),
      isError: !success,
    );
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.isEmpty && confirm.isEmpty) {
      _showMessage('Isi password baru terlebih dahulu', isError: true);
      return;
    }
    if (password != confirm) {
      _showMessage('Konfirmasi password tidak sama', isError: true);
      return;
    }

    final auth = context.read<AuthNotifier>();
    final success = await auth.updatePassword(password);
    if (!mounted) return;
    if (success) {
      _passwordController.clear();
      _confirmController.clear();
    }
    _showMessage(
      success
          ? 'Password diperbarui'
          : (auth.errorMessage ?? 'Gagal mengubah password'),
      isError: !success,
    );
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Tidak ada sesi')));
    }

    _hydrateKelasIfNeeded(auth);

    final tingkatOptions =
        auth.kelasList.map((k) => k.tingkat).toSet().toList()..sort();
    final jurusanOptions = _selectedTingkat == null
        ? <String>[]
        : (auth.kelasList
            .where((k) => k.tingkat == _selectedTingkat)
            .map((k) => k.jurusan)
            .toSet()
            .toList()
          ..sort());
    final saving = auth.isUpdatingProfile || auth.isUpdatingPassword;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            child: Text(user.email),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Peran',
              border: OutlineInputBorder(),
            ),
            child: Text(_roleLabel(user.role)),
          ),
          if (user.isSiswa && user.nisn != null && user.nisn!.isNotEmpty) ...[
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'NISN',
                border: OutlineInputBorder(),
              ),
              child: Text(user.nisn!),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              border: OutlineInputBorder(),
            ),
          ),
          if (user.isSiswa) ...[
            const SizedBox(height: 16),
            const Text(
              'Kelas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: ValueKey('tingkat-$_hydratedKelas-$_selectedTingkat'),
              initialValue: tingkatOptions.contains(_selectedTingkat)
                  ? _selectedTingkat
                  : null,
              decoration: const InputDecoration(
                labelText: 'Tingkat',
                border: OutlineInputBorder(),
              ),
              items: tingkatOptions
                  .map(
                    (tingkat) => DropdownMenuItem(
                      value: tingkat,
                      child: Text('Kelas $tingkat'),
                    ),
                  )
                  .toList(),
              onChanged: auth.isLoadingKelas
                  ? null
                  : (value) {
                      setState(() {
                        _selectedTingkat = value;
                        _selectedJurusan = null;
                        _kelasId = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedTingkat),
              initialValue: jurusanOptions.contains(_selectedJurusan)
                  ? _selectedJurusan
                  : null,
              decoration: const InputDecoration(
                labelText: 'Jurusan / rombel',
                border: OutlineInputBorder(),
              ),
              items: jurusanOptions
                  .map(
                    (jurusan) => DropdownMenuItem(
                      value: jurusan,
                      child: Text(jurusan),
                    ),
                  )
                  .toList(),
              onChanged: auth.isLoadingKelas
                  ? null
                  : (value) {
                      setState(() {
                        _selectedJurusan = value;
                        _kelasId = auth.kelasList
                            .where(
                              (k) =>
                                  k.tingkat == _selectedTingkat &&
                                  k.jurusan == value,
                            )
                            .map((k) => k.id)
                            .firstOrNull;
                      });
                    },
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : _saveProfile,
            child: auth.isUpdatingProfile
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan profil'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ubah password',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Minimal ${AppConstants.minPasswordLength} karakter. Akun Google juga bisa membuat password di sini.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password baru',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Konfirmasi password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: saving ? null : _savePassword,
            child: auth.isUpdatingPassword
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan password'),
          ),
        ],
      ),
    );
  }
}
