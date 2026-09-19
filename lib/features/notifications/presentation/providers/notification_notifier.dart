import 'package:flutter/foundation.dart';
import 'package:beranibicara/features/notifications/domain/entities/app_notification.dart';
import 'package:beranibicara/features/notifications/domain/usecases/get_unread_notification_count_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/list_notifications_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/register_device_token_usecase.dart';

class NotificationNotifier extends ChangeNotifier {
  final ListNotificationsUseCase listNotificationsUseCase;
  final GetUnreadNotificationCountUseCase getUnreadNotificationCountUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final RegisterDeviceTokenUseCase registerDeviceTokenUseCase;

  NotificationNotifier({
    required this.listNotificationsUseCase,
    required this.getUnreadNotificationCountUseCase,
    required this.markNotificationReadUseCase,
    required this.markAllNotificationsReadUseCase,
    required this.registerDeviceTokenUseCase,
  });

  List<AppNotification> _items = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingRoute;
  String? _registeredToken;

  List<AppNotification> get items => _items;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingRoute => _pendingRoute;

  void setPendingRoute(String route) {
    _pendingRoute = route;
    notifyListeners();
  }

  void clearPendingRoute() {
    _pendingRoute = null;
  }

  Future<void> registerToken({
    required String token,
    String? deviceOs,
  }) async {
    if (_registeredToken == token) return;
    final result = await registerDeviceTokenUseCase(
      token: token,
      deviceOs: deviceOs,
    );
    result.fold((_) {}, (_) {
      _registeredToken = token;
    });
    await refreshUnreadCount();
  }

  void clearSession() {
    _items = [];
    _unreadCount = 0;
    _registeredToken = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await listNotificationsUseCase();
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
      },
      (items) {
        _items = items;
        _unreadCount = items.where((item) => item.isUnread).length;
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    final result = await getUnreadNotificationCountUseCase();
    result.fold((_) {}, (count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  Future<void> markRead(int id) async {
    await markNotificationReadUseCase(id);
    _items = _items
        .map(
          (item) => item.id == id
              ? AppNotification(
                  id: item.id,
                  title: item.title,
                  body: item.body,
                  type: item.type,
                  relatedEntityType: item.relatedEntityType,
                  relatedEntityId: item.relatedEntityId,
                  route: item.route,
                  sentAt: item.sentAt,
                  readAt: DateTime.now(),
                )
              : item,
        )
        .toList();
    _unreadCount = _items.where((item) => item.isUnread).length;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await markAllNotificationsReadUseCase();
    final now = DateTime.now();
    _items = _items
        .map(
          (item) => AppNotification(
            id: item.id,
            title: item.title,
            body: item.body,
            type: item.type,
            relatedEntityType: item.relatedEntityType,
            relatedEntityId: item.relatedEntityId,
            route: item.route,
            sentAt: item.sentAt,
            readAt: item.readAt ?? now,
          ),
        )
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
