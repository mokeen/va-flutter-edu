// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stroke.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StrokeImpl _$$StrokeImplFromJson(Map<String, dynamic> json) => _$StrokeImpl(
  id: json['id'] as String,
  colorValue: (json['colorValue'] as num).toInt(),
  width: (json['width'] as num).toDouble(),
  points: (json['points'] as List<dynamic>)
      .map((e) => WBPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$StrokeImplToJson(_$StrokeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'colorValue': instance.colorValue,
      'width': instance.width,
      'points': instance.points,
    };
