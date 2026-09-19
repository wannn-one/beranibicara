import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/notifications/domain/repositories/notification_repository.dart';

class RegisterDeviceTokenUseCase {
  final NotificationRepository repository;
  RegisterDeviceTokenUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String token,
    String? deviceName,
    String? deviceOs,
  }) {
    return repository.registerDeviceToken(
      token: token,
      deviceName: deviceName,
      deviceOs: deviceOs,
    );
  }
}
