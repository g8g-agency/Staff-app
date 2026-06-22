// lib/features/orders/data/mappers/order_mapper.dart
import '../../domain/entities/menu_product.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order.dart';
import '../../../../shared/models/money.dart';
import '../dtos/order_dto.dart';

extension ModifierOptionMapper on ModifierOption {
  ModifierOptionDto toDto() {
    return ModifierOptionDto(
      id: id,
      name: name,
      priceInCents: price.amountInCents,
    );
  }
}

extension ModifierOptionDtoMapper on ModifierOptionDto {
  ModifierOption toDomain() {
    return ModifierOption(
      id: id,
      name: name,
      price: Money(amountInCents: priceInCents),
    );
  }
}

extension MenuProductMapper on MenuProduct {
  MenuProductDto toDto() {
    return MenuProductDto(
      id: id,
      name: name,
      priceInCents: price.amountInCents,
      category: category,
      availableModifiers: availableModifiers.map((m) => m.toDto()).toList(),
    );
  }
}

extension MenuProductDtoMapper on MenuProductDto {
  MenuProduct toDomain() {
    return MenuProduct(
      id: id,
      name: name,
      price: Money(amountInCents: priceInCents),
      category: category ?? '',
      availableModifiers: availableModifiers?.map((m) => m.toDomain()).toList() ?? [],
    );
  }
}

extension OrderItemMapper on OrderItem {
  OrderItemDto toDto() {
    return OrderItemDto(
      id: id,
      product: product.toDto(),
      quantity: quantity,
      selectedModifiers: selectedModifiers.map((m) => m.toDto()).toList(),
      seatNumber: seatNumber,
      status: status.name,
    );
  }
}

extension OrderItemDtoMapper on OrderItemDto {
  OrderItem toDomain() {
    return OrderItem(
      id: id,
      product: product.toDomain(),
      quantity: quantity,
      selectedModifiers: selectedModifiers?.map((m) => m.toDomain()).toList() ?? [],
      seatNumber: seatNumber ?? 1,
      status: OrderItemStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => OrderItemStatus.queued,
      ),
    );
  }
}

extension OrderMapper on Order {
  OrderDto toDto() {
    return OrderDto(
      id: id,
      tableId: tableId,
      items: items.map((i) => i.toDto()).toList(),
      status: status.name,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt.toIso8601String(),
      waiterName: waiterName,
      cancelLogs: cancelLogs,
    );
  }
}

extension OrderDtoMapper on OrderDto {
  Order toDomain() {
    return Order(
      id: id,
      tableId: tableId ?? '',
      items: items.map((i) => i.toDomain()).toList(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => OrderStatus.draft,
      ),
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
      waiterName: waiterName ?? 'Unknown',
      cancelLogs: cancelLogs ?? [],
    );
  }
}
