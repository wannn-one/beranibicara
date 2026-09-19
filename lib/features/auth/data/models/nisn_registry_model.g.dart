// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nisn_registry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NisnRegistryModelImpl _$$NisnRegistryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NisnRegistryModelImpl(
      nisn: json['nisn'] as String,
      namaSiswa: json['namaSiswa'] as String,
      tingkat: (json['tingkat'] as num?)?.toInt(),
      jurusan: json['jurusan'] as String?,
      isRegistered: json['isRegistered'] as bool? ?? false,
      userId: json['userId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      registeredAt: json['registeredAt'] == null
          ? null
          : DateTime.parse(json['registeredAt'] as String),
    );

Map<String, dynamic> _$$NisnRegistryModelImplToJson(
        _$NisnRegistryModelImpl instance) =>
    <String, dynamic>{
      'nisn': instance.nisn,
      'namaSiswa': instance.namaSiswa,
      'tingkat': instance.tingkat,
      'jurusan': instance.jurusan,
      'isRegistered': instance.isRegistered,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
      'registeredAt': instance.registeredAt?.toIso8601String(),
    };
