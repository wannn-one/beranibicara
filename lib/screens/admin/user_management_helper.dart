import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/screens/admin/user_blocking_dialogs.dart';
import 'package:beranibicara/screens/admin/user_deletion_dialog.dart';

final supabase = Supabase.instance.client;

class UserManagementHelper {
  // Dialog untuk mengelola user (role, block, unblock, delete)
  static void showUserManagementDialog(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kelola ${user['full_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Ubah Peran'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showChangeRoleDialog(context, user, onUpdate);
                },
              ),
              if (user['status'] != 'diblokir')
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.orange),
                  title: const Text('Blokir User'),
                  onTap: () {
                    Navigator.of(context).pop();
                    UserBlockingDialogs.showBlockDialog(context, user, onUpdate);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.lock_open, color: Colors.green),
                  title: const Text('Buka Blokir'),
                  onTap: () {
                    Navigator.of(context).pop();
                    UserBlockingDialogs.showUnblockDialog(context, user, onUpdate);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Hapus Data User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  UserDeletionDialog.showDeleteUserDialog(context, user, onUpdate);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk mengubah role
  static void _showChangeRoleDialog(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) {
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
                    try {
                      await supabase
                          .from('profiles')
                          .update({'role': selectedRole})
                          .eq('id', user['id']);

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Peran berhasil diperbarui!')),
                        );
                        onUpdate();
                      }
                    } catch (error) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
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

  // Helper methods untuk status user
  static String getStatusText(Map<String, dynamic> user) {
    final status = user['status'] ?? 'aktif';
    if (status == 'diblokir') {
      final blockedUntil = user['blocked_until'];
      if (blockedUntil != null) {
        final until = DateTime.parse(blockedUntil);
        final now = DateTime.now();
        if (until.isBefore(now)) {
          return 'Blokir Berakhir';
        }
        final duration = until.difference(now);
        if (duration.inDays > 0) {
          return 'Diblokir (${duration.inDays} hari)';
        } else if (duration.inHours > 0) {
          return 'Diblokir (${duration.inHours} jam)';
        } else {
          return 'Diblokir (${duration.inMinutes} menit)';
        }
      }
      return 'Diblokir Permanen';
    }
    if (status == 'deletion_requested') {
      return 'Minta Hapus Akun';
    }
    return status.toUpperCase();
  }

  static Color getStatusColor(Map<String, dynamic> user) {
    final status = user['status'] ?? 'aktif';
    switch (status) {
      case 'aktif':
        return Colors.green;
      case 'nonaktif':
        return Colors.orange;
      case 'diblokir':
        return Colors.red;
      case 'deletion_requested':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static Color? getCardColor(Map<String, dynamic> user) {
    final status = user['status'] ?? 'aktif';
    if (status == 'diblokir') {
      return Colors.red.withValues(alpha: 0.1);
    }
    if (status == 'deletion_requested') {
      return Colors.purple.withValues(alpha: 0.1);
    }
    return null;
  }

  static Widget buildUserActions(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) {
    final loggedInUserId = supabase.auth.currentUser!.id;
    if (loggedInUserId == user['id']) {
      return const Icon(Icons.person, color: Colors.blue);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tombol Block/Unblock
        if (user['status'] == 'diblokir')
          IconButton(
            icon: const Icon(Icons.lock_open, color: Colors.green),
            onPressed: () => UserBlockingDialogs.showUnblockDialog(context, user, onUpdate),
            tooltip: 'Buka Blokir',
          )
        else
          IconButton(
            icon: const Icon(Icons.block, color: Colors.orange),
            onPressed: () => UserBlockingDialogs.showBlockDialog(context, user, onUpdate),
            tooltip: 'Blokir User',
          ),
        // Tombol Hapus Data
        IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () => UserDeletionDialog.showDeleteUserDialog(context, user, onUpdate),
          tooltip: 'Hapus Data User',
        ),
      ],
    );
  }
}
