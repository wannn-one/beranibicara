import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/providers/cerita_kelas_notifier.dart';

class CeritaKelasListScreen extends StatefulWidget {
  const CeritaKelasListScreen({super.key});

  @override
  State<CeritaKelasListScreen> createState() => _CeritaKelasListScreenState();
}

class _CeritaKelasListScreenState extends State<CeritaKelasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthNotifier>().user;
      context.read<CeritaKelasNotifier>().loadList(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CeritaKelasNotifier>();
    final user = context.watch<AuthNotifier>().user;
    final canCreate = (user?.isSiswa == true && user?.kelasId != null) ||
        (user?.isGuru == true && notifier.waliKelas.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Cerita Kelas')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () =>
                  context.push(AppConstants.routeCreateCeritaKelas),
              child: const Icon(Icons.add),
            )
          : null,
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifier.items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      notifier.errorMessage ?? 'Belum ada cerita di kelas ini',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifier.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = notifier.items[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            context.push('/cerita-kelas/${item.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.gambarUrl != null &&
                                item.gambarUrl!.isNotEmpty)
                              Image.network(
                                item.gambarUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ListTile(
                              title: Text(item.judul),
                              subtitle: Text(
                                '${item.authorName ?? 'Teman sekelas'} · ${formatAppDate(item.createdAt)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
