import 'package:beranibicara/features/auth/domain/entities/auth_session_event.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

class WatchAuthSessionUseCase {
  final AuthRepository repository;

  WatchAuthSessionUseCase(this.repository);

  Stream<AuthSessionEvent> call() => repository.watchAuthSession();
}
