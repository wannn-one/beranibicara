import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/domain/entities/nisn_registry.dart';
import 'package:beranibicara/features/auth/domain/entities/kelas.dart';
import 'package:beranibicara/features/auth/domain/entities/auth_session_event.dart';
import 'package:beranibicara/features/auth/domain/entities/sign_up_result.dart';

/// Auth Repository Interface
/// This is the contract that the data layer must implement
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });

  /// Sign in with Google OAuth
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign up with email and password
  /// [role] defaults to 'siswa', can be 'guru' if specified
  /// [nisn] is optional - if provided, will verify against registry
  /// Sign up with email and password.
  /// [user] is null when email confirmation is required (no session yet).
  Future<Either<Failure, SignUpResult>> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role,
    String? nisn,
  });

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Get current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Verify NISN against registry
  /// Returns NisnRegistry if valid and available
  Future<Either<Failure, NisnRegistry>> verifyNisn(String nisn);

  /// Send password reset email
  Future<Either<Failure, void>> resetPassword(String email);

  /// Set a new password after recovery session
  Future<Either<Failure, void>> updatePassword(String password);

  /// True when the app was opened from the auth callback / recovery link
  Future<Either<Failure, bool>> isPasswordRecoveryLaunch();

  /// Auth client events (recovery, sign-in, sign-out)
  Stream<AuthSessionEvent> watchAuthSession();

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    required String userId,
    String? fullName,
    int? kelasId,
    String? nisn,
  });

  /// Check if user session is valid
  Future<Either<Failure, bool>> isSessionValid();

  /// List school classes for student profile completion
  Future<Either<Failure, List<Kelas>>> getKelasList();
}
