import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/domain/entities/nisn_registry.dart';
import 'package:beranibicara/features/auth/domain/entities/auth_session_event.dart';
import 'package:beranibicara/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/verify_nisn_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/get_kelas_list_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/complete_student_profile_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/watch_auth_session_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/is_password_recovery_launch_usecase.dart';
import 'package:beranibicara/features/auth/domain/entities/kelas.dart';
import 'package:beranibicara/features/notifications/data/services/fcm_service.dart';
import 'package:beranibicara/features/notifications/domain/usecases/unregister_device_token_usecase.dart';

/// Auth State
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth Provider using ChangeNotifier
class AuthNotifier extends ChangeNotifier {
  // Use cases
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final VerifyNisnUseCase verifyNisnUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final GetKelasListUseCase getKelasListUseCase;
  final CompleteStudentProfileUseCase completeStudentProfileUseCase;
  final WatchAuthSessionUseCase watchAuthSessionUseCase;
  final IsPasswordRecoveryLaunchUseCase isPasswordRecoveryLaunchUseCase;
  final UnregisterDeviceTokenUseCase unregisterDeviceTokenUseCase;

  // State
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  NisnRegistry? _verifiedNisn;
  bool _isNisnVerifying = false;
  List<Kelas> _kelasList = [];
  bool _isLoadingKelas = false;
  bool _isUpdatingProfile = false;
  bool _isResettingPassword = false;
  bool _isUpdatingPassword = false;
  bool _isPasswordRecovery = false;
  String? _kelasError;
  StreamSubscription<AuthSessionEvent>? _authSub;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  NisnRegistry? get verifiedNisn => _verifiedNisn;
  bool get isNisnVerifying => _isNisnVerifying;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isResettingPassword => _isResettingPassword;
  bool get isUpdatingPassword => _isUpdatingPassword;
  bool get isPasswordRecovery => _isPasswordRecovery;
  List<Kelas> get kelasList => _kelasList;
  bool get isLoadingKelas => _isLoadingKelas;
  bool get isUpdatingProfile => _isUpdatingProfile;
  String? get kelasError => _kelasError;

  AuthNotifier({
    required this.signInUseCase,
    required this.signInWithGoogleUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.verifyNisnUseCase,
    required this.resetPasswordUseCase,
    required this.updatePasswordUseCase,
    required this.updateProfileUseCase,
    required this.getKelasListUseCase,
    required this.completeStudentProfileUseCase,
    required this.watchAuthSessionUseCase,
    required this.isPasswordRecoveryLaunchUseCase,
    required this.unregisterDeviceTokenUseCase,
  }) {
    _authSub = watchAuthSessionUseCase().listen(_onAuthSessionEvent);
  }

  /// Initialize - check if user is already authenticated
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final recoveryLaunch = await isPasswordRecoveryLaunchUseCase();
    recoveryLaunch.fold((_) {}, (pending) {
      if (pending) _isPasswordRecovery = true;
    });

    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      },
      (user) {
        if (user != null) {
          _status = AuthStatus.authenticated;
          _user = user;
        } else {
          _status = AuthStatus.unauthenticated;
          _user = null;
        }
      },
    );

    notifyListeners();
  }

  Future<void> _onAuthSessionEvent(AuthSessionEvent event) async {
    switch (event) {
      case AuthSessionEvent.passwordRecovery:
        _isPasswordRecovery = true;
        await _reloadUser();
        break;
      case AuthSessionEvent.signedOut:
        _isPasswordRecovery = false;
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
        break;
      case AuthSessionEvent.signedIn:
        await _reloadUser();
        break;
    }
  }

  Future<void> _reloadUser() async {
    final result = await getCurrentUserUseCase();
    result.fold(
      (_) {},
      (user) {
        if (user != null) {
          _status = AuthStatus.authenticated;
          _user = user;
        }
      },
    );
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await signInUseCase(email: email, password: password);

    return result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        _user = null;
        notifyListeners();
        return false;
      },
      (user) {
        _status = AuthStatus.authenticated;
        _user = user;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await signInWithGoogleUseCase();

    return result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        _user = null;
        notifyListeners();
        return false;
      },
      (user) {
        _status = AuthStatus.authenticated;
        _user = user;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.siswa,
    String? nisn,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await signUpUseCase(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      nisn: nisn,
    );

    return result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        _user = null;
        notifyListeners();
        return false;
      },
      (signUpResult) {
        if (signUpResult.needsEmailConfirmation || signUpResult.user == null) {
          _status = AuthStatus.unauthenticated;
          _user = null;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
        _status = AuthStatus.authenticated;
        _user = signUpResult.user;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Sign out
  Future<bool> signOut() async {
    final token = FcmService.instance.currentToken;
    if (token != null) {
      await unregisterDeviceTokenUseCase(token);
    }
    await FcmService.instance.deleteLocalToken();

    final result = await signOutUseCase();

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return false;
      },
      (_) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        _errorMessage = null;
        _verifiedNisn = null;
        _kelasList = [];
        _kelasError = null;
        _isPasswordRecovery = false;
        notifyListeners();
        return true;
      },
    );
  }

  /// Verify NISN
  Future<bool> verifyNisn(String nisn) async {
    _isNisnVerifying = true;
    _verifiedNisn = null;
    _errorMessage = null;
    notifyListeners();

    final result = await verifyNisnUseCase(nisn);

    _isNisnVerifying = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _verifiedNisn = null;
        notifyListeners();
        return false;
      },
      (nisnRegistry) {
        _verifiedNisn = nisnRegistry;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Reset NISN verification state
  void clearNisnVerification() {
    _verifiedNisn = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _isResettingPassword = true;
    _errorMessage = null;
    notifyListeners();

    final result = await resetPasswordUseCase(email);
    _isResettingPassword = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> updatePassword(String password) async {
    _isUpdatingPassword = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updatePasswordUseCase(password);
    _isUpdatingPassword = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _isPasswordRecovery = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Update profile
  Future<bool> updateProfile({
    String? fullName,
    int? kelasId,
    String? nisn,
  }) async {
    if (_user == null) {
      _errorMessage = 'No authenticated user';
      return false;
    }

    _isUpdatingProfile = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateProfileUseCase(
      userId: _user!.id,
      fullName: fullName,
      kelasId: kelasId,
      nisn: nisn,
    );

    _isUpdatingProfile = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (updatedUser) {
        _user = updatedUser;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<void> loadKelasList({bool force = false}) async {
    if (_isLoadingKelas) return;
    if (!force && _kelasList.isNotEmpty) return;

    _isLoadingKelas = true;
    _kelasError = null;
    notifyListeners();

    final result = await getKelasListUseCase();
    _isLoadingKelas = false;

    result.fold(
      (failure) {
        _kelasError = failure.message;
        _kelasList = [];
        notifyListeners();
      },
      (kelas) {
        _kelasList = kelas;
        _kelasError = null;
        notifyListeners();
      },
    );
  }

  Future<bool> completeStudentProfile(int kelasId) async {
    if (_user == null) {
      _errorMessage = 'No authenticated user';
      return false;
    }

    _isUpdatingProfile = true;
    _errorMessage = null;
    notifyListeners();

    final result = await completeStudentProfileUseCase(
      user: _user!,
      kelasId: kelasId,
    );

    _isUpdatingProfile = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (updatedUser) {
        _user = updatedUser;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
