import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/domain/entities/nisn_registry.dart';
import 'package:beranibicara/features/auth/domain/entities/kelas.dart';
import 'package:beranibicara/features/auth/domain/entities/auth_session_event.dart';
import 'package:beranibicara/features/auth/domain/entities/sign_up_result.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';
import 'package:beranibicara/features/auth/data/datasources/auth_remote_datasource.dart';

/// Auth Repository Implementation
/// Implements the domain layer's AuthRepository interface
/// Converts exceptions to failures using Either pattern
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      // Check specific auth error codes
      if (e.message.contains('Invalid login') ||
          e.message.contains('Invalid email or password')) {
        return const Left(InvalidCredentialsFailure());
      }
      if (e.message.contains('Email not confirmed')) {
        return const Left(AuthFailure('Please verify your email first'));
      }
      return Left(AuthFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final userModel = await remoteDataSource.signInWithGoogle();
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      if (e.message.contains('cancelled')) {
        return const Left(AuthFailure('Google sign in cancelled'));
      }
      return Left(AuthFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignUpResult>> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.siswa,
    String? nisn,
  }) async {
    try {
      final outcome = await remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        nisn: nisn,
      );
      return Right(
        SignUpResult(
          user: outcome.user?.toEntity(),
          needsEmailConfirmation: outcome.needsEmailConfirmation,
        ),
      );
    } on EmailAlreadyInUseException {
      return const Left(EmailAlreadyInUseFailure());
    } on NisnAlreadyUsedException {
      return const Left(NisnAlreadyUsedFailure());
    } on NisnNotFoundException {
      return const Left(NisnNotFoundFailure());
    } on AuthException catch (e) {
      if (e.message.contains('weak password')) {
        return const Left(WeakPasswordFailure());
      }
      if (e.message.contains('invalid email')) {
        return const Left(InvalidEmailFailure());
      }
      return Left(AuthFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      if (userModel == null) {
        return const Right(null);
      }
      return Right(userModel.toEntity());
    } on UserNotFoundException {
      return const Left(UserNotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Right(null); // No session
    }
  }

  @override
  Future<Either<Failure, NisnRegistry>> verifyNisn(String nisn) async {
    try {
      final nisnModel = await remoteDataSource.verifyNisn(nisn);
      return Right(nisnModel.toEntity());
    } on NisnNotFoundException {
      return const Left(NisnNotFoundFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String password) async {
    try {
      await remoteDataSource.updatePassword(password);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isPasswordRecoveryLaunch() async {
    try {
      final pending = await remoteDataSource.isPasswordRecoveryLaunch();
      return Right(pending);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Stream<AuthSessionEvent> watchAuthSession() {
    return remoteDataSource.watchAuthSession();
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String userId,
    String? fullName,
    int? kelasId,
    String? nisn,
  }) async {
    try {
      final userModel = await remoteDataSource.updateProfile(
        userId: userId,
        fullName: fullName,
        kelasId: kelasId,
        nisn: nisn,
      );
      return Right(userModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Kelas>>> getKelasList() async {
    try {
      final models = await remoteDataSource.getKelasList();
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSessionValid() async {
    try {
      final isValid = await remoteDataSource.isSessionValid();
      return Right(isValid);
    } catch (e) {
      return const Right(false);
    }
  }
}
