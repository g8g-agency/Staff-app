// lib/features/tables/data/mappers/table_mapper.dart
import '../../domain/entities/restaurant_table.dart';
import '../dtos/table_dto.dart';

extension TableDtoMapper on TableDto {
  RestaurantTable toDomain() {
    TableStatus domainStatus;
    switch (status.toUpperCase()) {
      case 'FREE':
      case 'AVAILABLE':
        domainStatus = TableStatus.available;
        break;
      case 'ACTIVE_GUESTS':
      case 'ORDERING':
      case 'OCCUPIED':
        domainStatus = TableStatus.occupied;
        break;
      case 'PAYMENT_PENDING':
      case 'RESERVED':
        domainStatus = TableStatus.reserved;
        break;
      case 'ASSISTANCE_REQUESTED':
      case 'NEEDS_ATTENTION':
      case 'NEEDSATTENTION':
        domainStatus = TableStatus.needsAttention;
        break;
      case 'CLEANING':
        domainStatus = TableStatus.cleaning;
        break;
      default:
        domainStatus = TableStatus.unknown;
    }

    return RestaurantTable(
      id: id,
      label: label,
      capacity: capacity,
      status: domainStatus,
      activeOrderId: activeOrderId,
      occupiedSeats: occupiedSeats.map((s) => GuestSeat(
        seatNumber: s.seatNumber,
        guestName: s.guestName,
        orderedItemIds: s.orderedItemIds,
      )).toList(),
      mergedTableIds: mergedTableIds,
      floorId: floorId,
      floorName: floorName,
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
      floorId: floorId,
      floorName: floorName,
    );
  }
}
