// lib/shared/models/money.dart
import 'package:equatable/equatable.dart';

class Money extends Equatable {
  final int amountInCents;
  final String currency;

  const Money({
    required this.amountInCents,
    this.currency = 'INR',
  });

  double get asDouble => amountInCents / 100.0;

  String get formatted {
    final symbol = currency == 'INR' ? '₹' : currency;
    return '$symbol${asDouble.toStringAsFixed(2)}';
  }

  Money operator +(Money other) {
    assert(currency == other.currency, 'Cannot add different currencies');
    return Money(
      amountInCents: amountInCents + other.amountInCents,
      currency: currency,
    );
  }

  Money operator -(Money other) {
    assert(currency == other.currency, 'Cannot subtract different currencies');
    return Money(
      amountInCents: amountInCents - other.amountInCents,
      currency: currency,
    );
  }

  @override
  List<Object?> get props => [amountInCents, currency];
}
