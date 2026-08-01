// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_order_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeOrderNotifierHash() =>
    r'90dcffbb0b8c47696d47e76bd121d93a3a00da43';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ActiveOrderNotifier
    extends BuildlessAutoDisposeAsyncNotifier<Order?> {
  late final String tableId;

  FutureOr<Order?> build(String tableId);
}

/// See also [ActiveOrderNotifier].
@ProviderFor(ActiveOrderNotifier)
const activeOrderNotifierProvider = ActiveOrderNotifierFamily();

/// See also [ActiveOrderNotifier].
class ActiveOrderNotifierFamily extends Family<AsyncValue<Order?>> {
  /// See also [ActiveOrderNotifier].
  const ActiveOrderNotifierFamily();

  /// See also [ActiveOrderNotifier].
  ActiveOrderNotifierProvider call(String tableId) {
    return ActiveOrderNotifierProvider(tableId);
  }

  @override
  ActiveOrderNotifierProvider getProviderOverride(
    covariant ActiveOrderNotifierProvider provider,
  ) {
    return call(provider.tableId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'activeOrderNotifierProvider';
}

/// See also [ActiveOrderNotifier].
class ActiveOrderNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ActiveOrderNotifier, Order?> {
  /// See also [ActiveOrderNotifier].
  ActiveOrderNotifierProvider(String tableId)
    : this._internal(
        () => ActiveOrderNotifier()..tableId = tableId,
        from: activeOrderNotifierProvider,
        name: r'activeOrderNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$activeOrderNotifierHash,
        dependencies: ActiveOrderNotifierFamily._dependencies,
        allTransitiveDependencies:
            ActiveOrderNotifierFamily._allTransitiveDependencies,
        tableId: tableId,
      );

  ActiveOrderNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tableId,
  }) : super.internal();

  final String tableId;

  @override
  FutureOr<Order?> runNotifierBuild(covariant ActiveOrderNotifier notifier) {
    return notifier.build(tableId);
  }

  @override
  Override overrideWith(ActiveOrderNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ActiveOrderNotifierProvider._internal(
        () => create()..tableId = tableId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tableId: tableId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ActiveOrderNotifier, Order?>
  createElement() {
    return _ActiveOrderNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveOrderNotifierProvider && other.tableId == tableId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tableId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActiveOrderNotifierRef on AutoDisposeAsyncNotifierProviderRef<Order?> {
  /// The parameter `tableId` of this provider.
  String get tableId;
}

class _ActiveOrderNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ActiveOrderNotifier, Order?>
    with ActiveOrderNotifierRef {
  _ActiveOrderNotifierProviderElement(super.provider);

  @override
  String get tableId => (origin as ActiveOrderNotifierProvider).tableId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
