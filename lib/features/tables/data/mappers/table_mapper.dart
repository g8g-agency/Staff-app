// lib/features/tables/data/mappers/table_mapper.dart
import '../../domain/entities/restaurant_table.dart';
import '../dtos/table_dto.dart';

extension TableDtoMapper on TableDto {
  RestaurantTable toDomain() {
    return RestaurantTable(
      id: id,
      label: label,
      capacity: capacity,
      status: TableStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => TableStatus.unknown,
      ),
      activeOrderId: activeOrderId,
      occupiedSeats: occupiedSeats.map((s) => GuestSeat(
        seatNumber: s.seatNumber,
        guestName: s.guestName,
        orderedItemIds: s.orderedItemIds,
      )).toList(),
      mergedTableIds: mergedTableIds,
    );
  }
}

extension RestaurantTableMapper on RestaurantTable {
  TableDto toDto() {
    return TableDto(
      id: id,
      label: label,
      capacity: capacity,
      status: status.name,
      activeOrderId: activeOrderId,
      occupiedSeats: occupiedSeats.map((s) => GuestSeatDto(
        seatNumber: s.seatNumber,
        guestName: s.guestName,
        orderedItemIds: s.orderedItemIds,
      )).toList(),
      mergedTableIds: mergedTableIds,
    );
  }
}
