import 'package:flutter/material.dart';
import 'package:beranibicara/core/cache/hive_service.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/utils/legal_urls.dart';
import 'package:beranibicara/core/utils/url_utils.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _clearingCache = false;

  Future<void> _clearCache() async {
    final confirmed = await showConfirmDialog(
      context,
      'Hapus cache lokal?',
      'Data tersimpan di perangkat akan dihapus. Anda tidak akan keluar dari akun.',
      confirmText: 'Hapus',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingCache = true);
    await HiveService.clearAll();
    if (!mounted) return;
    setState(() => _clearingCache = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache lokal dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versi aplikasi'),
            subtitle: Text(
              '${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Syarat penggunaan'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => openExternalUrl(termsOfUseUrl()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Kebijakan privasi'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => openExternalUrl(privacyPolicyUrl()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Hapus cache lokal'),
            subtitle: const Text('Membersihkan data Hive di perangkat ini'),
            trailing: _clearingCache
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _clearingCache ? null : _clearCache,
          ),
        ],
      ),
    );
  }
}
