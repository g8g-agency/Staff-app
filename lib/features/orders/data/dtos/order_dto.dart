// lib/features/orders/data/dtos/order_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_dto.freezed.dart';
part 'order_dto.g.dart';

@freezed
abstract class ModifierOptionDto with _$ModifierOptionDto {
  const factory ModifierOptionDto({
    required String id,
    required String name,
    required int priceInCents,
  }) = _ModifierOptionDto;

  factory ModifierOptionDto.fromJson(Map<String, dynamic> json) => _$ModifierOptionDtoFromJson(json);
}

@freezed
abstract class MenuProductDto with _$MenuProductDto {
  const factory MenuProductDto({
    required String id,
    required String name,
    required int priceInCents,
    String? category,
    @Default([]) List<ModifierOptionDto>? availableModifiers,
  }) = _MenuProductDto;

  factory MenuProductDto.fromJson(Map<String, dynamic> json) => _$MenuProductDtoFromJson(json);
}

@freezed
abstract class OrderItemDto with _$OrderItemDto {
  const factory OrderItemDto({
    required String id,
    required MenuProductDto product,
    required int quantity,
    @Default([]) List<ModifierOptionDto>? selectedModifiers,
    int? seatNumber,
    required String status,
  }) = _OrderItemDto;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) => _$OrderItemDtoFromJson(json);
}

@freezed
abstract class OrderDto with _$OrderDto {
  const factory OrderDto({
    required String id,
    String? tableId,
    required List<OrderItemDto> items,
    required String status,
    required String createdAt,
    String? updatedAt,
    String? waiterName,
    @Default([]) List<String>? cancelLogs,
  }) = _OrderDto;

  factory OrderDto.fromJson(Map<String, dynamic> json) => _$OrderDtoFromJson(json);
}
