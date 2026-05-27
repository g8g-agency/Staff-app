// lib/features/tables/data/dtos/table_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'table_dto.freezed.dart';
part 'table_dto.g.dart';

@freezed
abstract class GuestSeatDto with _$GuestSeatDto {
  const factory GuestSeatDto({
    @JsonKey(name: 'seat_number') required int seatNumber,
    @JsonKey(name: 'guest_name') String? guestName,
    @JsonKey(name: 'ordered_item_ids') @Default([]) List<String> orderedItemIds,
  }) = _GuestSeatDto;

  factory GuestSeatDto.fromJson(Map<String, dynamic> json) => _$GuestSeatDtoFromJson(json);
}

@freezed
abstract class TableDto with _$TableDto {
  const TableDto._(); // Enable custom methods like toJson()

  const factory TableDto({
    required String id,
    required String label,
    required int capacity,
    required String status,
    @JsonKey(name: 'active_order_id') String? activeOrderId,
    @JsonKey(name: 'occupied_seats') @Default([]) List<GuestSeatDto> occupiedSeats,
    @JsonKey(name: 'merged_table_ids') @Default([]) List<String> mergedTableIds,
    @JsonKey(name: 'version_num') @Default(1) int versionNum,
  }) = _TableDto;

  factory TableDto.fromJson(Map<String, dynamic> json) => _$TableDtoFromJson(json);

  factory TableDto.fromMap(Map<String, dynamic> json) {
    final mappedJson = Map<String, dynamic>.from(json);
    if (mappedJson['label'] == null && mappedJson['table_number'] != null) {
      mappedJson['label'] = mappedJson['table_number']?.toString() ?? '';
    }
    if (mappedJson['status'] == null) {
      mappedJson['status'] = mappedJson['runtime_state'] ?? 'FREE';
    }
    mappedJson['capacity'] = mappedJson['capacity'] ?? 0;
    mappedJson['version_num'] = mappedJson['version_num'] ?? 1;

    return TableDto.fromJson(mappedJson);
  }
}
