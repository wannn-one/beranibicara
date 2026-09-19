import 'package:flutter/foundation.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/domain/usecases/list_profiles_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/update_user_role_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/update_user_status_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/list_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/create_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/assign_wali_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/update_student_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:beranibicara/features/admin/domain/entities/admin_stats.dart';

class AdminNotifier extends ChangeNotifier {
  final ListProfilesUseCase listProfilesUseCase;
  final UpdateUserRoleUseCase updateUserRoleUseCase;
  final UpdateUserStatusUseCase updateUserStatusUseCase;
  final ListKelasUseCase listKelasUseCase;
  final CreateKelasUseCase createKelasUseCase;
  final AssignWaliKelasUseCase assignWaliKelasUseCase;
  final UpdateStudentKelasUseCase updateStudentKelasUseCase;
  final GetAdminStatsUseCase getAdminStatsUseCase;

  AdminNotifier({
    required this.listProfilesUseCase,
    required this.updateUserRoleUseCase,
    required this.updateUserStatusUseCase,
    required this.listKelasUseCase,
    required this.createKelasUseCase,
    required this.assignWaliKelasUseCase,
    required this.updateStudentKelasUseCase,
    required this.getAdminStatsUseCase,
  });

  List<ManagedProfile> _profiles = [];
  List<ManagedKelas> _kelasList = [];
  AdminStats? _stats;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<ManagedProfile> get profiles => _profiles;
  List<ManagedKelas> get kelasList => _kelasList;
  AdminStats? get stats => _stats;
  List<ManagedProfile> get waliCandidates => _profiles
      .where(
        (p) =>
            (p.role == UserRole.guru || p.role == UserRole.admin) &&
            p.status == UserStatus.aktif,
      )
      .toList();
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await listProfilesUseCase();
    _isLoading = false;

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _profiles = [];
      },
      (profiles) {
        _profiles = profiles;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  Future<void> loadKelas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final kelasResult = await listKelasUseCase();
    final profileResult = await listProfilesUseCase();
    _isLoading = false;

    kelasResult.fold(
      (failure) {
        _errorMessage = failure.message;
        _kelasList = [];
      },
      (kelas) {
        _kelasList = kelas;
      },
    );
    profileResult.fold(
      (_) {},
      (profiles) {
        _profiles = profiles;
      },
    );
    notifyListeners();
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await getAdminStatsUseCase();
    _isLoading = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _stats = null;
      },
      (stats) {
        _stats = stats;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  Future<bool> changeRole({
    required String actorId,
    required String userId,
    required UserRole role,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateUserRoleUseCase(
      actorId: actorId,
      userId: userId,
      role: role,
    );
    _isSaving = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (updated) {
        _profiles = _profiles
            .map((profile) => profile.id == updated.id ? updated : profile)
            .toList();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> changeStatus({
    required String actorId,
    required String userId,
    required UserStatus status,
    String? reason,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateUserStatusUseCase(
      actorId: actorId,
      userId: userId,
      status: status,
      reason: reason,
    );
    _isSaving = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (updated) {
        _profiles = _profiles
            .map((profile) => profile.id == updated.id ? updated : profile)
            .toList();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> changeStudentKelas({
    required String userId,
    required int? kelasId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateStudentKelasUseCase(
      userId: userId,
      kelasId: kelasId,
    );
    _isSaving = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (updated) {
        _profiles = _profiles
            .map((profile) => profile.id == updated.id ? updated : profile)
            .toList();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> addKelas({
    required int tingkat,
    required String jurusan,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createKelasUseCase(
      tingkat: tingkat,
      jurusan: jurusan,
    );
    _isSaving = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (kelas) {
        _kelasList = [..._kelasList, kelas]
          ..sort((a, b) {
            final tingkatCompare = a.tingkat.compareTo(b.tingkat);
            if (tingkatCompare != 0) return tingkatCompare;
            return a.jurusan.compareTo(b.jurusan);
          });
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> setWaliKelas({
    required int kelasId,
    required String? waliKelasId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await assignWaliKelasUseCase(
      kelasId: kelasId,
      waliKelasId: waliKelasId,
    );
    _isSaving = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (updated) {
        _kelasList = _kelasList
            .map((kelas) => kelas.id == updated.id ? updated : kelas)
            .toList();
        notifyListeners();
        return true;
      },
    );
  }
}
