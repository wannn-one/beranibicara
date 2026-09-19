// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'balasan_laporan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BalasanLaporanModel {
  int get id => throw _privateConstructorUsedError;
  int get reportId => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String get pesan => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get authorName => throw _privateConstructorUsedError;
  String? get authorRole => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BalasanLaporanModelCopyWith<BalasanLaporanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BalasanLaporanModelCopyWith<$Res> {
  factory $BalasanLaporanModelCopyWith(
          BalasanLaporanModel value, $Res Function(BalasanLaporanModel) then) =
      _$BalasanLaporanModelCopyWithImpl<$Res, BalasanLaporanModel>;
  @useResult
  $Res call(
      {int id,
      int reportId,
      String authorId,
      String pesan,
      DateTime createdAt,
      String? authorName,
      String? authorRole});
}

/// @nodoc
class _$BalasanLaporanModelCopyWithImpl<$Res, $Val extends BalasanLaporanModel>
    implements $BalasanLaporanModelCopyWith<$Res> {
  _$BalasanLaporanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportId = null,
    Object? authorId = null,
    Object? pesan = null,
    Object? createdAt = null,
    Object? authorName = freezed,
    Object? authorRole = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as int,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      pesan: null == pesan
          ? _value.pesan
          : pesan // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      authorName: freezed == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String?,
      authorRole: freezed == authorRole
          ? _value.authorRole
          : authorRole // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BalasanLaporanModelImplCopyWith<$Res>
    implements $BalasanLaporanModelCopyWith<$Res> {
  factory _$$BalasanLaporanModelImplCopyWith(_$BalasanLaporanModelImpl value,
          $Res Function(_$BalasanLaporanModelImpl) then) =
      __$$BalasanLaporanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int reportId,
      String authorId,
      String pesan,
      DateTime createdAt,
      String? authorName,
      String? authorRole});
}

/// @nodoc
class __$$BalasanLaporanModelImplCopyWithImpl<$Res>
    extends _$BalasanLaporanModelCopyWithImpl<$Res, _$BalasanLaporanModelImpl>
    implements _$$BalasanLaporanModelImplCopyWith<$Res> {
  __$$BalasanLaporanModelImplCopyWithImpl(_$BalasanLaporanModelImpl _value,
      $Res Function(_$BalasanLaporanModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportId = null,
    Object? authorId = null,
    Object? pesan = null,
    Object? createdAt = null,
    Object? authorName = freezed,
    Object? authorRole = freezed,
  }) {
    return _then(_$BalasanLaporanModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as int,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      pesan: null == pesan
          ? _value.pesan
          : pesan // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      authorName: freezed == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String?,
      authorRole: freezed == authorRole
          ? _value.authorRole
          : authorRole // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$BalasanLaporanModelImpl extends _BalasanLaporanModel {
  const _$BalasanLaporanModelImpl(
      {required this.id,
      required this.reportId,
      required this.authorId,
      required this.pesan,
      required this.createdAt,
      this.authorName,
      this.authorRole})
      : super._();

  @override
  final int id;
  @override
  final int reportId;
  @override
  final String authorId;
  @override
  final String pesan;
  @override
  final DateTime createdAt;
  @override
  final String? authorName;
  @override
  final String? authorRole;

  @override
  String toString() {
    return 'BalasanLaporanModel(id: $id, reportId: $reportId, authorId: $authorId, pesan: $pesan, createdAt: $createdAt, authorName: $authorName, authorRole: $authorRole)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BalasanLaporanModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reportId, reportId) ||
                other.reportId == reportId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.pesan, pesan) || other.pesan == pesan) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorRole, authorRole) ||
                other.authorRole == authorRole));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, reportId, authorId, pesan,
      createdAt, authorName, authorRole);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BalasanLaporanModelImplCopyWith<_$BalasanLaporanModelImpl> get copyWith =>
      __$$BalasanLaporanModelImplCopyWithImpl<_$BalasanLaporanModelImpl>(
          this, _$identity);
}

abstract class _BalasanLaporanModel extends BalasanLaporanModel {
  const factory _BalasanLaporanModel(
      {required final int id,
      required final int reportId,
      required final String authorId,
      required final String pesan,
      required final DateTime createdAt,
      final String? authorName,
      final String? authorRole}) = _$BalasanLaporanModelImpl;
  const _BalasanLaporanModel._() : super._();

  @override
  int get id;
  @override
  int get reportId;
  @override
  String get authorId;
  @override
  String get pesan;
  @override
  DateTime get createdAt;
  @override
  String? get authorName;
  @override
  String? get authorRole;
  @override
  @JsonKey(ignore: true)
  _$$BalasanLaporanModelImplCopyWith<_$BalasanLaporanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
