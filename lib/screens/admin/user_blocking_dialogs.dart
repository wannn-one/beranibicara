import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class UserBlockingDialogs {
  // Dialog untuk mengelola user (role, block, unblock)
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
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Blokir User'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showBlockDialog(context, user, onUpdate);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.lock_open, color: Colors.green),
                  title: const Text('Buka Blokir'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showUnblockDialog(context, user, onUpdate);
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

  // Dialog untuk memblokir user
  static void showBlockDialog(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) {
    final reasonController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String blockType = 'temporary'; // temporary or permanent

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Blokir ${user['full_name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jenis Pemblokiran:'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                blockType = 'temporary';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: blockType == 'temporary' ? Colors.blue : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: blockType == 'temporary' ? Colors.blue.withValues(alpha: 0.1) : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    blockType == 'temporary' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: blockType == 'temporary' ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Sementara'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                blockType = 'permanent';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: blockType == 'permanent' ? Colors.blue : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: blockType == 'permanent' ? Colors.blue.withValues(alpha: 0.1) : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    blockType == 'permanent' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: blockType == 'permanent' ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Permanen'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (blockType == 'temporary') ...[
                      const SizedBox(height: 16),
                      const Text('Blokir sampai:'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    selectedDate = date;
                                  });
                                }
                              },
                              child: Text(selectedDate != null 
                                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                  : 'Pilih Tanggal'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    selectedTime = time;
                                  });
                                }
                              },
                              child: Text(selectedTime != null 
                                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Pilih Waktu'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Alasan Pemblokiran *',
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan alasan pemblokiran...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alasan pemblokiran harus diisi!')),
                      );
                      return;
                    }

                    if (blockType == 'temporary' && (selectedDate == null || selectedTime == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih tanggal dan waktu untuk pemblokiran sementara!')),
                      );
                      return;
                    }

                    await _blockUser(context, user, reasonController.text.trim(), blockType, selectedDate, selectedTime, onUpdate);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Blokir User', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog untuk membuka blokir user
  static void showUnblockDialog(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Buka Blokir ${user['full_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yakin ingin membuka blokir untuk ${user['full_name']}?'),
              const SizedBox(height: 8),
              if (user['blocked_reason'] != null) ...[
                const Text('Alasan pemblokiran:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(user['blocked_reason']),
                const SizedBox(height: 8),
              ],
              if (user['blocked_until'] != null) ...[
                const Text('Diblokir sampai:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(DateTime.parse(user['blocked_until']).toString()),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _unblockUser(context, user, onUpdate);
                if (context.mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Buka Blokir', style: TextStyle(color: Colors.white)),
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

  // Method untuk memblokir user
  static Future<void> _blockUser(BuildContext context, Map<String, dynamic> user, String reason, String blockType, DateTime? date, TimeOfDay? time, VoidCallback onUpdate) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      DateTime? blockedUntil;
      
      if (blockType == 'temporary' && date != null && time != null) {
        blockedUntil = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }

      await supabase.from('profiles').update({
        'status': 'diblokir',
        'blocked_until': blockedUntil?.toIso8601String(),
        'blocked_reason': reason,
        'blocked_by': currentUserId,
        'blocked_at': DateTime.now().toIso8601String(),
      }).eq('id', user['id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user['full_name']} berhasil diblokir!')),
        );
        onUpdate();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memblokir user: $error')),
        );
      }
    }
  }

  // Method untuk membuka blokir user
  static Future<void> _unblockUser(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) async {
    try {
      await supabase.from('profiles').update({
        'status': 'aktif',
        'blocked_until': null,
        'blocked_reason': null,
        'blocked_by': null,
        'blocked_at': null,
      }).eq('id', user['id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user['full_name']} berhasil dibuka blokirnya!')),
        );
        onUpdate();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka blokir user: $error')),
        );
      }
    }
  }
}

// Helper class untuk status user
class UserStatusHelper {
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
      default:
        return Colors.grey;
    }
  }

  static Color? getCardColor(Map<String, dynamic> user) {
    final status = user['status'] ?? 'aktif';
    if (status == 'diblokir') {
      return Colors.red.withValues(alpha: 0.1);
    }
    return null;
  }

  static Widget buildUserActions(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) {
    final loggedInUserId = supabase.auth.currentUser!.id;
    if (loggedInUserId == user['id']) {
      return const Icon(Icons.person, color: Colors.blue);
    }

    final status = user['status'] ?? 'aktif';
    if (status == 'diblokir') {
      return IconButton(
        icon: const Icon(Icons.lock_open, color: Colors.green),
        onPressed: () => UserBlockingDialogs.showUnblockDialog(context, user, onUpdate),
        tooltip: 'Buka Blokir',
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.block, color: Colors.red),
        onPressed: () => UserBlockingDialogs.showBlockDialog(context, user, onUpdate),
        tooltip: 'Blokir User',
      );
    }
  }
}
