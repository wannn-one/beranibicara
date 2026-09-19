import 'package:flutter/foundation.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';
import 'package:beranibicara/features/socialization/domain/usecases/list_socialization_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/get_socialization_by_id_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/create_socialization_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/update_socialization_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/delete_socialization_usecase.dart';

class SocializationNotifier extends ChangeNotifier {
  final ListSocializationUseCase listSocializationUseCase;
  final GetSocializationByIdUseCase getSocializationByIdUseCase;
  final CreateSocializationUseCase createSocializationUseCase;
  final UpdateSocializationUseCase updateSocializationUseCase;
  final DeleteSocializationUseCase deleteSocializationUseCase;

  SocializationNotifier({
    required this.listSocializationUseCase,
    required this.getSocializationByIdUseCase,
    required this.createSocializationUseCase,
    required this.updateSocializationUseCase,
    required this.deleteSocializationUseCase,
  });

  List<Socialization> _items = [];
  Socialization? _current;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<Socialization> get items => _items;
  Socialization? get current => _current;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await listSocializationUseCase();
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

  Future<void> loadById(int id) async {
    _isLoading = true;
    _current = null;
    _errorMessage = null;
    notifyListeners();

    final result = await getSocializationByIdUseCase(id);
    _isLoading = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (item) {
        _current = item;
      },
    );
    notifyListeners();
  }

  Future<bool> create({
    required String authorId,
    required String title,
    required String content,
    required String imagePath,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createSocializationUseCase(
      authorId: authorId,
      title: title,
      content: content,
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

  void _replaceItem(Socialization item) {
    _current = item;
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      final next = [..._items];
      next[index] = item;
      _items = next;
    }
  }

  Future<bool> update({
    required int id,
    required String title,
    required String content,
    String? imagePath,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateSocializationUseCase(
      id: id,
      title: title,
      content: content,
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
        _replaceItem(item);
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> delete(int id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await deleteSocializationUseCase(id);
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
}
