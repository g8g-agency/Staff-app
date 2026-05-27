// lib/features/tables/domain/entities/restaurant_table.dart
import 'package:equatable/equatable.dart';

enum TableStatus {
  available,
  occupied,
  reserved,
  needsAttention,
  cleaning,
  unknown,
  projectionPending,
  recovering,
}

class GuestSeat extends Equatable {
  final int seatNumber;
  final String? guestName;
  final List<String> orderedItemIds;

  const GuestSeat({
    required this.seatNumber,
    this.guestName,
    required this.orderedItemIds,
  });

  GuestSeat copyWith({
    int? seatNumber,
    String? guestName,
    List<String>? orderedItemIds,
  }) {
    return GuestSeat(
      seatNumber: seatNumber ?? this.seatNumber,
      guestName: guestName ?? this.guestName,
      orderedItemIds: orderedItemIds ?? this.orderedItemIds,
    );
  }

  @override
  List<Object?> get props => [seatNumber, guestName, orderedItemIds];
}

class RestaurantTable extends Equatable {
  final String id;
  final String label;
  final int capacity;
  final TableStatus status;
  final String? activeOrderId;
  final List<GuestSeat> occupiedSeats;
  final List<String> mergedTableIds;

  const RestaurantTable({
    required this.id,
    required this.label,
    required this.capacity,
    required this.status,
    this.activeOrderId,
    this.occupiedSeats = const [],
    this.mergedTableIds = const [],
  });

  bool get canAcceptGuests => status == TableStatus.available || status == TableStatus.cleaning;
  bool get isMerged => mergedTableIds.isNotEmpty;

  RestaurantTable updateStatus(TableStatus newStatus, {String? orderId}) {
    return RestaurantTable(
      id: id,
      label: label,
      capacity: capacity,
      status: newStatus,
      activeOrderId: orderId ?? activeOrderId,
      occupiedSeats: occupiedSeats,
      mergedTableIds: mergedTableIds,
    );
  }

  RestaurantTable copyWith({
    String? id,
    String? label,
    int? capacity,
    TableStatus? status,
    String? activeOrderId,
    List<GuestSeat>? occupiedSeats,
    List<String>? mergedTableIds,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
      mergedTableIds: mergedTableIds ?? this.mergedTableIds,
    );
  }

  @override
  List<Object?> get props => [id, label, capacity, status, activeOrderId, occupiedSeats, mergedTableIds];
}
