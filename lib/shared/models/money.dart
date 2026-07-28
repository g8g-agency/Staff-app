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
    return Money(
      amountInCents: amountInCents + other.amountInCents,
      currency: currency.toUpperCase(),
    );
  }

  Money operator -(Money other) {
    return Money(
      amountInCents: amountInCents - other.amountInCents,
      currency: currency.toUpperCase(),
    );
  }

  @override
  List<Object?> get props => [amountInCents, currency];
}
