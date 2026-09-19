import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/notifications/data/services/fcm_service.dart';
import 'package:beranibicara/features/notifications/presentation/providers/notification_notifier.dart';

class FcmBinder extends StatefulWidget {
  const FcmBinder({super.key, required this.child});

  final Widget child;

  @override
  State<FcmBinder> createState() => _FcmBinderState();
}

class _FcmBinderState extends State<FcmBinder> {
  String? _boundUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindIfNeeded());
  }

  Future<void> _bindIfNeeded() async {
    if (!mounted) return;
    final auth = context.read<AuthNotifier>();
    final notifications = context.read<NotificationNotifier>();
    final user = auth.user;

    if (user == null) {
      if (_boundUserId != null) {
        notifications.clearSession();
      }
      _boundUserId = null;
      return;
    }
    if (_boundUserId == user.id) return;
    _boundUserId = user.id;

    await FcmService.instance.initialize(
      onOpenRoute: (route) {
        notifications.setPendingRoute(route);
      },
      onToken: (token) {
        notifications.registerToken(
          token: token,
          deviceOs: FcmService.instance.deviceOsLabel(),
        );
      },
    );

    final token =
        FcmService.instance.currentToken ?? await FcmService.instance.refreshToken();
    if (token != null) {
      await notifications.registerToken(
        token: token,
        deviceOs: FcmService.instance.deviceOsLabel(),
      );
    }
    await notifications.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthNotifier>().user?.id;
    final pendingRoute =
        context.select((NotificationNotifier n) => n.pendingRoute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId != _boundUserId) {
        _bindIfNeeded();
      }
      if (pendingRoute != null && pendingRoute.isNotEmpty && mounted) {
        context.read<NotificationNotifier>().clearPendingRoute();
        context.go(pendingRoute);
      }
    });

    return widget.child;
  }
}
