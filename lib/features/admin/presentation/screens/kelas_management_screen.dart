import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/presentation/providers/admin_notifier.dart';

class KelasManagementScreen extends StatefulWidget {
  const KelasManagementScreen({super.key});

  @override
  State<KelasManagementScreen> createState() => _KelasManagementScreenState();
}

class _KelasManagementScreenState extends State<KelasManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminNotifier>().loadKelas();
      }
    });
  }

  Future<void> _createKelas() async {
    final tingkatController = TextEditingController(text: '4');
    final jurusanController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Kelas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tingkatController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tingkat (1–6)'),
            ),
            TextField(
              controller: jurusanController,
              decoration: const InputDecoration(labelText: 'Nama/jurusan (contoh: 4A)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (created != true || !mounted) return;

    final tingkat = int.tryParse(tingkatController.text.trim());
    final success = await context.read<AdminNotifier>().addKelas(
          tingkat: tingkat ?? 0,
          jurusan: jurusanController.text,
        );
    if (!mounted) return;
    final notifier = context.read<AdminNotifier>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Kelas ditambahkan' : (notifier.errorMessage ?? 'Gagal'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _assignWali(ManagedKelas kelas) async {
    final notifier = context.read<AdminNotifier>();
    final selected = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Wali ${kelas.label}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Tanpa wali kelas'),
          ),
          ...notifier.waliCandidates.map(
            (guru) => SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, guru.id),
              child: Text(guru.displayName),
            ),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;

    final success = await notifier.setWaliKelas(
      kelasId: kelas.id,
      waliKelasId: selected.isEmpty ? null : selected,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Wali kelas diperbarui'
              : (notifier.errorMessage ?? 'Gagal mengubah wali'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AdminNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kelas')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createKelas,
        child: const Icon(Icons.add),
      ),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifier.kelasList.isEmpty
              ? const Center(child: Text('Belum ada kelas'))
              : ListView.separated(
                  itemCount: notifier.kelasList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final kelas = notifier.kelasList[index];
                    return ListTile(
                      title: Text(kelas.label),
                      subtitle: Text(
                        kelas.waliKelasName == null
                            ? 'Belum ada wali kelas'
                            : 'Wali: ${kelas.waliKelasName}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _assignWali(kelas),
                        child: const Text('Ubah wali'),
                      ),
                    );
                  },
                ),
    );
  }
}
