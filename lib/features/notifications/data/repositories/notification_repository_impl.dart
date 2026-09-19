import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:beranibicara/features/notifications/domain/entities/app_notification.dart';
import 'package:beranibicara/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> registerDeviceToken({
    required String token,
    String? deviceName,
    String? deviceOs,
  }) async {
    try {
      await remoteDataSource.upsertToken(
        token: token,
        deviceName: deviceName,
        deviceOs: deviceOs,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal mendaftar perangkat: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterDeviceToken(String token) async {
    try {
      await remoteDataSource.deactivateToken(token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal melepas perangkat: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppNotification>>> listNotifications() async {
    try {
      final models = await remoteDataSource.listNotifications();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat notifikasi: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> unreadCount() async {
    try {
      return Right(await remoteDataSource.unreadCount());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menghitung notifikasi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(int id) async {
    try {
      await remoteDataSource.markRead(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menandai notifikasi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await remoteDataSource.markAllRead();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menandai semua notifikasi: $e'));
    }
  }
}
