import 'package:flutter/foundation.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/tanggapan_cerita.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/wali_kelas_option.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/list_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/get_cerita_kelas_by_id_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/create_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/update_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/delete_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/list_tanggapan_cerita_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/add_tanggapan_cerita_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/delete_tanggapan_cerita_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/list_wali_kelas_options_usecase.dart';

class CeritaKelasNotifier extends ChangeNotifier {
  final ListCeritaKelasUseCase listCeritaKelasUseCase;
  final GetCeritaKelasByIdUseCase getCeritaKelasByIdUseCase;
  final CreateCeritaKelasUseCase createCeritaKelasUseCase;
  final UpdateCeritaKelasUseCase updateCeritaKelasUseCase;
  final DeleteCeritaKelasUseCase deleteCeritaKelasUseCase;
  final ListTanggapanCeritaUseCase listTanggapanCeritaUseCase;
  final AddTanggapanCeritaUseCase addTanggapanCeritaUseCase;
  final DeleteTanggapanCeritaUseCase deleteTanggapanCeritaUseCase;
  final ListWaliKelasOptionsUseCase listWaliKelasOptionsUseCase;

  CeritaKelasNotifier({
    required this.listCeritaKelasUseCase,
    required this.getCeritaKelasByIdUseCase,
    required this.createCeritaKelasUseCase,
    required this.updateCeritaKelasUseCase,
    required this.deleteCeritaKelasUseCase,
    required this.listTanggapanCeritaUseCase,
    required this.addTanggapanCeritaUseCase,
    required this.deleteTanggapanCeritaUseCase,
    required this.listWaliKelasOptionsUseCase,
  });

  List<CeritaKelas> _items = [];
  CeritaKelas? _current;
  List<TanggapanCerita> _comments = [];
  List<WaliKelasOption> _waliKelas = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<CeritaKelas> get items => _items;
  CeritaKelas? get current => _current;
  List<TanggapanCerita> get comments => _comments;
  List<WaliKelasOption> get waliKelas => _waliKelas;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadList(User? user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int? kelasId;
    List<int>? kelasIds;
    if (user?.isSiswa == true) {
      kelasId = user!.kelasId;
      if (kelasId == null) {
        _items = [];
        _isLoading = false;
        _errorMessage = 'Pilih kelas di profil sebelum melihat cerita kelas.';
        notifyListeners();
        return;
      }
    } else if (user?.isGuru == true) {
      await _loadWaliKelas(user!.id);
      kelasIds = _waliKelas.map((k) => k.id).toList();
      if (kelasIds.isEmpty) {
        _items = [];
        _isLoading = false;
        _errorMessage =
            'Anda belum menjadi wali kelas. Hubungi TPPK untuk di-assign.';
        notifyListeners();
        return;
      }
    }

    final result = await listCeritaKelasUseCase(
      kelasId: kelasId,
      kelasIds: kelasIds,
    );
    _isLoading = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _items = [];
      },
      (items) {
        _items = items;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  Future<void> loadWaliKelas(String userId) async {
    await _loadWaliKelas(userId);
    notifyListeners();
  }

  Future<void> _loadWaliKelas(String userId) async {
    final result = await listWaliKelasOptionsUseCase(userId);
    result.fold(
      (_) => _waliKelas = [],
      (items) => _waliKelas = items,
    );
  }

  Future<void> loadById(int id) async {
    _isLoading = true;
    _current = null;
    _comments = [];
    _errorMessage = null;
    notifyListeners();

    final result = await getCeritaKelasByIdUseCase(id);
    await result.fold(
      (failure) async {
        _errorMessage = failure.message;
      },
      (item) async {
        _current = item;
        await _loadComments(id);
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadComments(int ceritaId) async {
    final result = await listTanggapanCeritaUseCase(ceritaId);
    result.fold(
      (_) => _comments = [],
      (items) => _comments = items,
    );
  }

  Future<bool> create({
    required String authorId,
    required int kelasId,
    required String judul,
    required String konten,
    String? imagePath,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createCeritaKelasUseCase(
      authorId: authorId,
      kelasId: kelasId,
      judul: judul,
      konten: konten,
      imagePath: imagePath,
    );
    _isSaving = false;
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (item) {
        _items = [item, ..._items];
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> update({
    required int id,
    required String judul,
    required String konten,
    String? imagePath,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateCeritaKelasUseCase(
      id: id,
      judul: judul,
      konten: konten,
      imagePath: imagePath,
    );
    _isSaving = false;
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (item) {
        _current = item;
        final index = _items.indexWhere((e) => e.id == item.id);
        if (index >= 0) {
          final next = [..._items];
          next[index] = item;
          _items = next;
        }
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> delete(int id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await deleteCeritaKelasUseCase(id);
    _isSaving = false;
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _items = _items.where((item) => item.id != id).toList();
        if (_current?.id == id) _current = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> addComment({
    required int ceritaId,
    required String authorId,
    required String tanggapan,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await addTanggapanCeritaUseCase(
      ceritaId: ceritaId,
      authorId: authorId,
      tanggapan: tanggapan,
    );
    _isSaving = false;
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (item) {
        _comments = [..._comments, item];
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> deleteComment(int id) async {
    final result = await deleteTanggapanCeritaUseCase(id);
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _comments = _comments.where((c) => c.id != id).toList();
        notifyListeners();
        return true;
      },
    );
  }
}
