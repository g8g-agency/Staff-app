// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservations_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reservationsRepositoryHash() =>
    r'f3cf01ddd6232fcbcbf8032b88fe0e582fea856d';

/// See also [reservationsRepository].
@ProviderFor(reservationsRepository)
final reservationsRepositoryProvider =
    Provider<ReservationsRepository>.internal(
      reservationsRepository,
      name: r'reservationsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reservationsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReservationsRepositoryRef = ProviderRef<ReservationsRepository>;
String _$reservationsNotifierHash() =>
    r'cd9714f6ca7c16c16bb021e04faa5632c4c7baed';

/// See also [ReservationsNotifier].
@ProviderFor(ReservationsNotifier)
final reservationsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ReservationsNotifier,
      ReservationsState
    >.internal(
      ReservationsNotifier.new,
      name: r'reservationsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reservationsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReservationsNotifier = AutoDisposeAsyncNotifier<ReservationsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
