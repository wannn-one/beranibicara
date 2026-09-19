// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evidence_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EvidenceModel {
  String get id => throw _privateConstructorUsedError;
  String get reportId => throw _privateConstructorUsedError;
  String get fileUrl => throw _privateConstructorUsedError;
  String get fileType => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EvidenceModelCopyWith<EvidenceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvidenceModelCopyWith<$Res> {
  factory $EvidenceModelCopyWith(
          EvidenceModel value, $Res Function(EvidenceModel) then) =
      _$EvidenceModelCopyWithImpl<$Res, EvidenceModel>;
  @useResult
  $Res call(
      {String id,
      String reportId,
      String fileUrl,
      String fileType,
      DateTime createdAt});
}

/// @nodoc
class _$EvidenceModelCopyWithImpl<$Res, $Val extends EvidenceModel>
    implements $EvidenceModelCopyWith<$Res> {
  _$EvidenceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportId = null,
    Object? fileUrl = null,
    Object? fileType = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EvidenceModelImplCopyWith<$Res>
    implements $EvidenceModelCopyWith<$Res> {
  factory _$$EvidenceModelImplCopyWith(
          _$EvidenceModelImpl value, $Res Function(_$EvidenceModelImpl) then) =
      __$$EvidenceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String reportId,
      String fileUrl,
      String fileType,
      DateTime createdAt});
}

/// @nodoc
class __$$EvidenceModelImplCopyWithImpl<$Res>
    extends _$EvidenceModelCopyWithImpl<$Res, _$EvidenceModelImpl>
    implements _$$EvidenceModelImplCopyWith<$Res> {
  __$$EvidenceModelImplCopyWithImpl(
      _$EvidenceModelImpl _value, $Res Function(_$EvidenceModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportId = null,
    Object? fileUrl = null,
    Object? fileType = null,
    Object? createdAt = null,
  }) {
    return _then(_$EvidenceModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$EvidenceModelImpl extends _EvidenceModel {
  const _$EvidenceModelImpl(
      {required this.id,
      required this.reportId,
      required this.fileUrl,
      required this.fileType,
      required this.createdAt})
      : super._();

  @override
  final String id;
  @override
  final String reportId;
  @override
  final String fileUrl;
  @override
  final String fileType;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'EvidenceModel(id: $id, reportId: $reportId, fileUrl: $fileUrl, fileType: $fileType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvidenceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reportId, reportId) ||
                other.reportId == reportId) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, reportId, fileUrl, fileType, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EvidenceModelImplCopyWith<_$EvidenceModelImpl> get copyWith =>
      __$$EvidenceModelImplCopyWithImpl<_$EvidenceModelImpl>(this, _$identity);
}

abstract class _EvidenceModel extends EvidenceModel {
  const factory _EvidenceModel(
      {required final String id,
      required final String reportId,
      required final String fileUrl,
      required final String fileType,
      required final DateTime createdAt}) = _$EvidenceModelImpl;
  const _EvidenceModel._() : super._();

  @override
  String get id;
  @override
  String get reportId;
  @override
  String get fileUrl;
  @override
  String get fileType;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$EvidenceModelImplCopyWith<_$EvidenceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
