import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/socialization/presentation/providers/socialization_notifier.dart';

class SocializationListScreen extends StatefulWidget {
  const SocializationListScreen({super.key});

  @override
  State<SocializationListScreen> createState() => _SocializationListScreenState();
}

class _SocializationListScreenState extends State<SocializationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SocializationNotifier>().loadList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SocializationNotifier>();
    final role = context.watch<AuthNotifier>().user?.role;
    final canCreate = role == UserRole.tppk || role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Sosialisasi')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () =>
                  context.push(AppConstants.routeCreateSocialization),
              child: const Icon(Icons.add),
            )
          : null,
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifier.items.isEmpty
              ? const Center(child: Text('Belum ada artikel sosialisasi'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifier.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = notifier.items[index];
                    final date = item.publishedAt ?? item.createdAt;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            context.push('/socialization/${item.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.coverImageUrl != null &&
                                item.coverImageUrl!.isNotEmpty)
                              Image.network(
                                item.coverImageUrl!,
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
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.authorName ?? 'TPPK'} · ${formatAppDate(date)}',
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
