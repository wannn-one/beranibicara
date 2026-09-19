import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/presentation/providers/admin_notifier.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  UserRole? _roleFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminNotifier>().loadProfiles();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ManagedProfile> _filtered(List<ManagedProfile> profiles) {
    final query = _searchController.text.trim().toLowerCase();
    return profiles.where((profile) {
      if (_roleFilter != null && profile.role != _roleFilter) return false;
      if (query.isEmpty) return true;
      return profile.displayName.toLowerCase().contains(query) ||
          (profile.nisn ?? '').contains(query);
    }).toList();
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

  String _statusLabel(UserStatus status) {
    switch (status) {
      case UserStatus.aktif:
        return 'Aktif';
      case UserStatus.nonAktif:
        return 'Nonaktif';
      case UserStatus.blocked:
        return 'Diblokir';
    }
  }

  Future<void> _changeRole(ManagedProfile profile) async {
    final actorId = context.read<AuthNotifier>().user?.id;
    if (actorId == null) return;
    if (actorId == profile.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa mengubah role akun sendiri')),
      );
      return;
    }

    final selected = await showDialog<UserRole>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Ubah role ${profile.displayName}'),
        children: UserRole.values
            .map(
              (role) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, role),
                child: Text(_roleLabel(role)),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;

    final success = await context.read<AdminNotifier>().changeRole(
          actorId: actorId,
          userId: profile.id,
          role: selected,
        );
    if (!mounted) return;
    final notifier = context.read<AdminNotifier>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Role diperbarui'
              : (notifier.errorMessage ?? 'Gagal mengubah role'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changeStatus(ManagedProfile profile) async {
    final actorId = context.read<AuthNotifier>().user?.id;
    if (actorId == null) return;
    if (actorId == profile.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa mengubah status akun sendiri')),
      );
      return;
    }

    final selected = await showDialog<UserStatus>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Ubah status ${profile.displayName}'),
        children: UserStatus.values
            .map(
              (status) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, status),
                child: Text(_statusLabel(status)),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;

    String? reason;
    if (selected == UserStatus.blocked) {
      final controller = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Alasan blokir'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Wajib diisi'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Blokir'),
            ),
          ],
        ),
      );
      if (reason == null || !mounted) return;
    }

    final success = await context.read<AdminNotifier>().changeStatus(
          actorId: actorId,
          userId: profile.id,
          status: selected,
          reason: reason,
        );
    if (!mounted) return;
    final notifier = context.read<AdminNotifier>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Status diperbarui'
              : (notifier.errorMessage ?? 'Gagal mengubah status'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changeKelas(ManagedProfile profile) async {
    final notifier = context.read<AdminNotifier>();
    if (notifier.kelasList.isEmpty) {
      await notifier.loadKelas();
      if (!mounted) return;
    }

    final selected = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Kelas ${profile.displayName}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, -1),
            child: const Text('Tanpa kelas'),
          ),
          ...notifier.kelasList.map(
            (kelas) => SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, kelas.id),
              child: Text(kelas.label),
            ),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;

    final success = await notifier.changeStudentKelas(
      userId: profile.id,
      kelasId: selected < 0 ? null : selected,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Kelas siswa diperbarui'
              : (notifier.errorMessage ?? 'Gagal mengubah kelas'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AdminNotifier>();
    final profiles = _filtered(notifier.profiles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NISN',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _roleFilter == null,
                  onSelected: (_) => setState(() => _roleFilter = null),
                ),
                const SizedBox(width: 8),
                ...UserRole.values.map(
                  (role) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_roleLabel(role)),
                      selected: _roleFilter == role,
                      onSelected: (_) => setState(() => _roleFilter = role),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: notifier.isLoading
                ? const Center(child: CircularProgressIndicator())
                : profiles.isEmpty
                    ? const Center(child: Text('Tidak ada pengguna'))
                    : ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return ListTile(
                            title: Text(profile.displayName),
                            subtitle: Text(
                              '${_roleLabel(profile.role)} · ${_statusLabel(profile.status)}'
                              '${profile.nisn != null ? ' · ${profile.nisn}' : ''}',
                            ),
                            trailing: notifier.isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'role') {
                                        _changeRole(profile);
                                      } else if (value == 'status') {
                                        _changeStatus(profile);
                                      } else if (value == 'kelas') {
                                        _changeKelas(profile);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'role',
                                        child: Text('Ubah role'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'status',
                                        child: Text('Ubah status'),
                                      ),
                                      if (profile.role == UserRole.siswa)
                                        const PopupMenuItem(
                                          value: 'kelas',
                                          child: Text('Ubah kelas'),
                                        ),
                                    ],
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
