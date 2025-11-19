import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/widgets/student_drawer.dart';
import 'package:beranibicara/screens/auth/verify_current_password.dart';

final supabase = Supabase.instance.client;

class StudentProfileScreen extends StatefulWidget {
  static const String routeName = '/student-profile';
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _currentUser = supabase.auth.currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*, kelas:kelas_id(tingkat, jurusan)')
          .eq('id', _currentUser!.id)
          .single();

      if (mounted) {
        setState(() {
          _userProfile = response;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: $error')),
        );
      }
    }
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = _userProfile?['full_name'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Nama'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama tidak boleh kosong')),
                  );
                  return;
                }

                try {
                  supabase
                      .from('profiles')
                      .update({'full_name': newName})
                      .eq('id', _currentUser!.id);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama berhasil diperbarui!')),
                    );
                    _fetchUserProfile(); // Refresh data
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui nama: $error')),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const StudentDrawer(currentRoute: StudentProfileScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUserProfile,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF36A395),
                            child: Text(
                              (_userProfile?['full_name'] ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userProfile?['full_name'] ?? 'Nama tidak tersedia',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?.email ?? 'Email tidak tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_userProfile?['kelas'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF36A395).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Kelas ${_userProfile!['kelas']['tingkat']} ${_userProfile!['kelas']['jurusan']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF36A395),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Akun',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 24),
                          ListTile(
                            leading: const Icon(Icons.person_outline, color: Color(0xFF36A395)),
                            title: const Text('Nama Lengkap'),
                            subtitle: Text(_userProfile?['full_name'] ?? 'Tidak ada nama'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Color(0xFF36A395)),
                              onPressed: _showEditNameDialog,
                              tooltip: 'Edit nama',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            leading: const Icon(Icons.email_outlined, color: Color(0xFF36A395)),
                            title: const Text('Email'),
                            subtitle: Text(_currentUser?.email ?? 'Tidak ada email'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            leading: const Icon(Icons.badge_outlined, color: Color(0xFF36A395)),
                            title: const Text('Peran'),
                            subtitle: Text(_userProfile?['role']?.toUpperCase() ?? 'SISWA'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_userProfile?['kelas'] != null)
                            ListTile(
                              leading: const Icon(Icons.school_outlined, color: Color(0xFF36A395)),
                              title: const Text('Kelas'),
                              subtitle: Text(
                                'Kelas ${_userProfile!['kelas']['tingkat']} ${_userProfile!['kelas']['jurusan']}',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settings Section
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline, color: Color(0xFF36A395)),
                          title: const Text('Ubah Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const VerifyCurrentPasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline, color: Color(0xFF36A395)),
                          title: const Text('Bantuan & Dukungan'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur bantuan akan segera tersedia'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                          title: const Text('Hapus Akun', style: TextStyle(color: Colors.red)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.red),
                          onTap: _showDeleteAccountDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Info
                  Card(
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 60,
                            width: 60,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Berani Bicara',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Versi 1.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Akun'),
          content: const Text(
              'Apakah Anda yakin ingin mengajukan penghapusan akun? Tindakan ini akan mengirimkan permintaan ke admin untuk menghapus akun Anda secara permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase
                      .from('profiles')
                      .update({'status': 'deletion_requested'})
                      .eq('id', _currentUser!.id);

                  if (mounted && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Permintaan penghapusan akun telah dikirim.')),
                    );
                    _fetchUserProfile(); // Refresh data
                  }
                } catch (error) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Gagal mengirim permintaan: $error')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ajukan Penghapusan'),
            ),
          ],
        );
      },
    );
  }
}
