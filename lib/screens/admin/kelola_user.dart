import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/screens/widgets/admin_drawer.dart';

final supabase = Supabase.instance.client;

class ManageUsersScreen extends StatefulWidget {
  static const String routeName = '/manage-users';
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*, kelas:kelas_id(tingkat, jurusan)')
          .order('created_at', ascending: false);
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data pengguna: $error')),
        );
      }
      return [];
    }
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ubah Peran untuk ${user['full_name']}'),
              content: DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                items: ['siswa', 'guru', 'tppk'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setDialogState(() {
                      selectedRole = newValue;
                    });
                  }
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await supabase
                          .from('profiles')
                          .update({'role': selectedRole})
                          .eq('id', user['id']);

                      if (mounted) {
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Peran berhasil diperbarui!')),
                        );
                        setState(() {
                          _usersFuture = _fetchUsers();
                        });
                      }
                    } catch (error) {
                       if (mounted) {
                         navigator.pop();
                         scaffoldMessenger.showSnackBar(
                           SnackBar(content: Text('Gagal memperbarui peran: $error')),
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
      },
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Peringatan'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
        title: const Text('Kelola Pengguna'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      drawer: const AdminDrawer(currentRoute: ManageUsersScreen.routeName),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Terjadi error saat memuat data.'));
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pengguna terdaftar.'));
          }

          final users = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _usersFuture = _fetchUsers();
              });
            },
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                
                String subtitleText = 'Peran: ${user['role']}';
                if (user['role'] == 'siswa') {
                  String userKelas = 'Belum diatur';
                  if (user['kelas'] != null) {
                    userKelas =
                        'Kelas ${user['kelas']['tingkat']} ${user['kelas']['jurusan']}';
                  }
                  subtitleText += ' | Kelas: $userKelas';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(user['full_name']?[0] ?? 'U')),
                    title: Text(user['full_name'] ?? 'Nama tidak tersedia'),
                    subtitle: Text(subtitleText),
                    onTap: () {
                      final loggedInUserId = supabase.auth.currentUser!.id;

                      if (loggedInUserId == user['id']) {
                        _showWarningDialog('Anda tidak dapat mengubah peran diri sendiri!');
                      } else {
                        _showChangeRoleDialog(user);
                      }
                    }
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}