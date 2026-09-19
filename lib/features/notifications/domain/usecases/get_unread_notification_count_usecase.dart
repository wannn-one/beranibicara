import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/notifications/domain/repositories/notification_repository.dart';

class GetUnreadNotificationCountUseCase {
  final NotificationRepository repository;
  GetUnreadNotificationCountUseCase(this.repository);

  Future<Either<Failure, int>> call() => repository.unreadCount();
}
