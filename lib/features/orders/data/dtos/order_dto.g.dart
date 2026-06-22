// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModifierOptionDto _$ModifierOptionDtoFromJson(Map<String, dynamic> json) =>
    _ModifierOptionDto(
      id: json['id'] as String,
      name: json['name'] as String,
      priceInCents: (json['priceInCents'] as num).toInt(),
    );

Map<String, dynamic> _$ModifierOptionDtoToJson(_ModifierOptionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'priceInCents': instance.priceInCents,
    };

_MenuProductDto _$MenuProductDtoFromJson(Map<String, dynamic> json) =>
    _MenuProductDto(
      id: json['id'] as String,
      name: json['name'] as String,
      priceInCents: (json['priceInCents'] as num).toInt(),
      category: json['category'] as String?,
      availableModifiers:
          (json['availableModifiers'] as List<dynamic>?)
              ?.map(
                (e) => ModifierOptionDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MenuProductDtoToJson(_MenuProductDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'priceInCents': instance.priceInCents,
      'category': instance.category,
      'availableModifiers': instance.availableModifiers,
    };

_OrderItemDto _$OrderItemDtoFromJson(Map<String, dynamic> json) =>
    _OrderItemDto(
      id: json['id'] as String,
      product: MenuProductDto.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
      selectedModifiers:
          (json['selectedModifiers'] as List<dynamic>?)
              ?.map(
                (e) => ModifierOptionDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      seatNumber: (json['seatNumber'] as num?)?.toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$OrderItemDtoToJson(_OrderItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product': instance.product,
      'quantity': instance.quantity,
      'selectedModifiers': instance.selectedModifiers,
      'seatNumber': instance.seatNumber,
      'status': instance.status,
    };

_OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => _OrderDto(
  id: json['id'] as String,
  tableId: json['tableId'] as String?,
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String?,
  waiterName: json['waiterName'] as String?,
  cancelLogs:
      (json['cancelLogs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$OrderDtoToJson(_OrderDto instance) => <String, dynamic>{
  'id': instance.id,
  'tableId': instance.tableId,
  'items': instance.items,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'waiterName': instance.waiterName,
  'cancelLogs': instance.cancelLogs,
};
