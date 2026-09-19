import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/notifications/domain/entities/app_notification.dart';
import 'package:beranibicara/features/notifications/domain/repositories/notification_repository.dart';

class ListNotificationsUseCase {
  final NotificationRepository repository;
  ListNotificationsUseCase(this.repository);

  Future<Either<Failure, List<AppNotification>>> call() {
    return repository.listNotifications();
  }
}
