import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/widgets/admin_drawer.dart';
import 'package:beranibicara/screens/admin/user_management_helper.dart';

final supabase = Supabase.instance.client;

class ManageUsersScreen extends StatefulWidget {
  static const String routeName = '/manage-users';
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isDataLoaded = false;
  
  // Filter state variables
  String? _selectedRole;
  int? _selectedKelasId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*, kelas:kelas_id(tingkat, jurusan), blocked_by_profile:blocked_by(full_name)')
          .order('created_at', ascending: false);
      
      final realUsers = (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      if (mounted) {
        setState(() {
          _allUsers = realUsers;
          _isDataLoaded = true;
        });
        
        // Apply current filters
        _applyFilters();
      }
      return _filteredUsers;

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data pengguna: $error')),
        );
      }
      return [];
    }
  }

  // Apply filters to the users list
  void _applyFilters() {
    _filteredUsers = _allUsers.where((user) {
      // Filter by role
      if (_selectedRole != null && user['role'] != _selectedRole) {
        return false;
      }
      
      // Filter by kelas_id (specific class)
      if (_selectedKelasId != null) {
        return user['kelas_id'] == _selectedKelasId;
      }
      
      // Filter by status
      if (_selectedStatus != null && user['status'] != _selectedStatus) {
        return false;
      }
      
      return true;
    }).toList();
  }

  // Update filters and refresh the list
  void _updateFilters() {
    _applyFilters();
  }

  // Get available classes from users with kelas data
  List<Map<String, dynamic>> _getAvailableKelas() {
    final kelasMap = <int, Map<String, dynamic>>{};
    
    for (var user in _allUsers) {
      if (user['kelas'] != null && user['kelas_id'] != null) {
        final kelasId = user['kelas_id'] as int;
        if (!kelasMap.containsKey(kelasId)) {
          kelasMap[kelasId] = {
            'id': kelasId,
            'tingkat': user['kelas']['tingkat'],
            'jurusan': user['kelas']['jurusan'],
            'display': '${user['kelas']['tingkat']}${user['kelas']['jurusan']}',
          };
        }
      }
    }
    
    final kelasList = kelasMap.values.toList();
    // Sort by tingkat then jurusan
    kelasList.sort((a, b) {
      if (a['tingkat'] != b['tingkat']) {
        return a['tingkat'].compareTo(b['tingkat']);
      }
      return a['jurusan'].compareTo(b['jurusan']);
    });
    
    return kelasList;
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
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const AdminDrawer(currentRoute: ManageUsersScreen.routeName),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('Terjadi error saat memuat data.'));
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada pengguna yang sesuai filter.'));
                }
                final users = _filteredUsers;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _isDataLoaded = false;
                      _usersFuture = _fetchUsers();
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];

                      String subtitleText = 'Peran: ${user['role']}';
                      if (user['role'] == 'siswa') {
                        String userKelas = 'Belum diatur';
                        if (user['kelas'] != null) {
                          userKelas = 'Kelas ${user['kelas']['tingkat']} ${user['kelas']['jurusan']}';
                        }
                        subtitleText += ' | Kelas: $userKelas';
                      }
                      
                      // Add status info
                      String statusText = UserManagementHelper.getStatusText(user);
                      subtitleText += ' | Status: $statusText';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: UserManagementHelper.getCardColor(user),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: UserManagementHelper.getStatusColor(user),
                            child: Text(user['full_name']?[0] ?? 'U'),
                          ),
                          title: Text(user['full_name'] ?? 'Nama tidak tersedia'),
                          subtitle: Text(subtitleText),
                          trailing: UserManagementHelper.buildUserActions(context, user, () {
                            setState(() {
                              _usersFuture = _fetchUsers();
                            });
                          }),
                          onTap: () {
                            final loggedInUserId = supabase.auth.currentUser!.id;

                            if (loggedInUserId == user['id']) {
                              _showWarningDialog('Anda tidak dapat mengubah diri sendiri!');
                            } else {
                              UserManagementHelper.showUserManagementDialog(context, user, () {
                                setState(() {
                                  _usersFuture = _fetchUsers();
                                });
                              });
                            }
                          }
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Peran',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('Semua Peran'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Peran'),
                        ),
                        ...['siswa', 'guru', 'tppk'].map((role) =>
                          DropdownMenuItem<String>(
                            value: role,
                            child: Text(role.toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                          _updateFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Kelas Filter
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelas',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedKelasId,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: Text(_isDataLoaded ? 'Semua Kelas' : 'Memuat kelas...'),
                      items: _isDataLoaded ? [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Semua Kelas'),
                        ),
                        ..._getAvailableKelas().map((kelas) =>
                          DropdownMenuItem<int>(
                            value: kelas['id'],
                            child: Text(kelas['display']),
                          ),
                        ),
                      ] : [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Memuat kelas...'),
                        ),
                      ],
                      onChanged: _isDataLoaded ? (value) {
                        setState(() {
                          _selectedKelasId = value;
                          _updateFilters();
                        });
                      } : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status Filter
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('Semua Status'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Status'),
                        ),
                        ...['aktif', 'diblokir', 'deletion_requested'].map((status) =>
                          DropdownMenuItem<String>(
                            value: status,
                            child: Text(UserManagementHelper.getStatusText({'status': status})),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                          _updateFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter Summary & Clear Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredUsers.length} dari ${_allUsers.length} pengguna',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (_selectedRole != null || _selectedKelasId != null || _selectedStatus != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedRole = null;
                          _selectedKelasId = null;
                          _selectedStatus = null;
                          _updateFilters();
                        });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Filter'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
