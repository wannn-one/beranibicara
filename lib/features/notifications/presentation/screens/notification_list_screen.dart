import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/features/notifications/presentation/providers/notification_notifier.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationNotifier>().loadNotifications();
    });
  }

  String _routeFor(String? route, String? type, String? id) {
    if (route != null && route.isNotEmpty) return route;
    if (id == null || id.isEmpty) return AppConstants.routeDashboard;
    switch (type) {
      case 'report':
        return '${AppConstants.routeReports}/$id';
      case 'socialization':
        return '${AppConstants.routeSocialization}/$id';
      case 'cerita_kelas':
        return '${AppConstants.routeCeritaKelas}/$id';
      default:
        return AppConstants.routeDashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NotificationNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (notifier.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllRead(),
              child: const Text('Tandai semua'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.loadNotifications,
        child: notifier.isLoading && notifier.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : notifier.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Belum ada notifikasi')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notifier.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = notifier.items[index];
                      return ListTile(
                        leading: Icon(
                          item.isUnread
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                          color: item.isUnread
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${item.body}\n${formatAppDateTime(item.sentAt)}',
                        ),
                        isThreeLine: true,
                        onTap: () async {
                          if (item.isUnread) {
                            await notifier.markRead(item.id);
                          }
                          if (!context.mounted) return;
                          context.push(
                            _routeFor(
                              item.route,
                              item.relatedEntityType,
                              item.relatedEntityId,
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
