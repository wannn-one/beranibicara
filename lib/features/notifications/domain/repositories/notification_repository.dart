import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, void>> registerDeviceToken({
    required String token,
    String? deviceName,
    String? deviceOs,
  });

  Future<Either<Failure, void>> unregisterDeviceToken(String token);

  Future<Either<Failure, List<AppNotification>>> listNotifications();

  Future<Either<Failure, int>> unreadCount();

  Future<Either<Failure, void>> markRead(int id);

  Future<Either<Failure, void>> markAllRead();
}
