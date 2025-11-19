import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class UserDeletionDialog {
  // Dialog untuk menghapus data user
  static void showDeleteUserDialog(BuildContext context, Map<String, dynamic> user, VoidCallback onUpdate) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Data ${user['full_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PERINGATAN: Tindakan ini tidak dapat dibatalkan!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Data yang akan dihapus:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Profil pengguna'),
                const Text('• Semua laporan yang dibuat'),
                const Text('• Semua bukti/file yang diupload'),
                const Text('• Riwayat notifikasi'),
                const Text('• Data kelas (jika siswa)'),
                const Text('• Semua aktivitas terkait'),
                const SizedBox(height: 16),
                Text(
                  'Yakin ingin menghapus semua data ${user['full_name']}?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Penghapusan *',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan alasan penghapusan data...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Setelah data dihapus, pengguna tidak akan bisa login lagi dan semua riwayat akan hilang permanen.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
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
                    const SnackBar(content: Text('Alasan penghapusan harus diisi!')),
                  );
                  return;
                }

                // Konfirmasi dengan mengetik "HAPUS"
                final confirmed = await _showDeleteConfirmation(context, user['full_name']);
                if (confirmed && context.mounted) {
                  await _deleteUser(context, user, reasonController.text.trim(), onUpdate);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus Data Permanen', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Dialog konfirmasi dengan mengetik "HAPUS"
  static Future<bool> _showDeleteConfirmation(BuildContext context, String userName) async {
    final confirmController = TextEditingController();
    
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Terakhir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ketik "HAPUS" untuk mengkonfirmasi penghapusan data $userName'),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'Ketik "HAPUS"',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmController.text.trim().toUpperCase() == 'HAPUS') {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ketik "HAPUS" untuk konfirmasi')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Method untuk menghapus user dan semua data terkait
  static Future<void> _deleteUser(BuildContext context, Map<String, dynamic> user, String reason, VoidCallback onUpdate) async {
    try {
      // Panggil RPC untuk hapus user
      await supabase.rpc('delete_user_completely', params: {
        'user_id_to_delete': user['id'],
        'deletion_reason': reason,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data ${user['full_name']} berhasil dihapus!')),
        );
        onUpdate();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus data user: $error')),
        );
      }
    }
  }
}
