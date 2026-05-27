// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuestSeatDto _$GuestSeatDtoFromJson(Map<String, dynamic> json) =>
    _GuestSeatDto(
      seatNumber: (json['seat_number'] as num).toInt(),
      guestName: json['guest_name'] as String?,
      orderedItemIds:
          (json['ordered_item_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$GuestSeatDtoToJson(_GuestSeatDto instance) =>
    <String, dynamic>{
      'seat_number': instance.seatNumber,
      'guest_name': instance.guestName,
      'ordered_item_ids': instance.orderedItemIds,
    };

_TableDto _$TableDtoFromJson(Map<String, dynamic> json) => _TableDto(
  id: json['id'] as String,
  label: json['label'] as String,
  capacity: (json['capacity'] as num).toInt(),
  status: json['status'] as String,
  activeOrderId: json['active_order_id'] as String?,
  occupiedSeats:
      (json['occupied_seats'] as List<dynamic>?)
          ?.map((e) => GuestSeatDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  mergedTableIds:
      (json['merged_table_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  versionNum: (json['version_num'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$TableDtoToJson(_TableDto instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'capacity': instance.capacity,
  'status': instance.status,
  'active_order_id': instance.activeOrderId,
  'occupied_seats': instance.occupiedSeats,
  'merged_table_ids': instance.mergedTableIds,
  'version_num': instance.versionNum,
};
