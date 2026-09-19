import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/notifications/domain/repositories/notification_repository.dart';

class UnregisterDeviceTokenUseCase {
  final NotificationRepository repository;
  UnregisterDeviceTokenUseCase(this.repository);

  Future<Either<Failure, void>> call(String token) {
    return repository.unregisterDeviceToken(token);
  }
}
