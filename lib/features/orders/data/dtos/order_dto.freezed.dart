// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModifierOptionDto {

 String get id; String get name; int get priceInCents;
/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModifierOptionDtoCopyWith<ModifierOptionDto> get copyWith => _$ModifierOptionDtoCopyWithImpl<ModifierOptionDto>(this as ModifierOptionDto, _$identity);

  /// Serializes this ModifierOptionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModifierOptionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceInCents, priceInCents) || other.priceInCents == priceInCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,priceInCents);

@override
String toString() {
  return 'ModifierOptionDto(id: $id, name: $name, priceInCents: $priceInCents)';
}


}

/// @nodoc
abstract mixin class $ModifierOptionDtoCopyWith<$Res>  {
  factory $ModifierOptionDtoCopyWith(ModifierOptionDto value, $Res Function(ModifierOptionDto) _then) = _$ModifierOptionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int priceInCents
});




}
/// @nodoc
class _$ModifierOptionDtoCopyWithImpl<$Res>
    implements $ModifierOptionDtoCopyWith<$Res> {
  _$ModifierOptionDtoCopyWithImpl(this._self, this._then);

  final ModifierOptionDto _self;
  final $Res Function(ModifierOptionDto) _then;

/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? priceInCents = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceInCents: null == priceInCents ? _self.priceInCents : priceInCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModifierOptionDto].
extension ModifierOptionDtoPatterns on ModifierOptionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModifierOptionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModifierOptionDto value)  $default,){
final _that = this;
switch (_that) {
case _ModifierOptionDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModifierOptionDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int priceInCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that.id,_that.name,_that.priceInCents);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int priceInCents)  $default,) {final _that = this;
switch (_that) {
case _ModifierOptionDto():
return $default(_that.id,_that.name,_that.priceInCents);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int priceInCents)?  $default,) {final _that = this;
switch (_that) {
case _ModifierOptionDto() when $default != null:
return $default(_that.id,_that.name,_that.priceInCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModifierOptionDto implements ModifierOptionDto {
  const _ModifierOptionDto({required this.id, required this.name, required this.priceInCents});
  factory _ModifierOptionDto.fromJson(Map<String, dynamic> json) => _$ModifierOptionDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  int priceInCents;

/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModifierOptionDtoCopyWith<_ModifierOptionDto> get copyWith => __$ModifierOptionDtoCopyWithImpl<_ModifierOptionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModifierOptionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModifierOptionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceInCents, priceInCents) || other.priceInCents == priceInCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,priceInCents);

@override
String toString() {
  return 'ModifierOptionDto(id: $id, name: $name, priceInCents: $priceInCents)';
}


}

/// @nodoc
abstract mixin class _$ModifierOptionDtoCopyWith<$Res> implements $ModifierOptionDtoCopyWith<$Res> {
  factory _$ModifierOptionDtoCopyWith(_ModifierOptionDto value, $Res Function(_ModifierOptionDto) _then) = __$ModifierOptionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int priceInCents
});




}
/// @nodoc
class __$ModifierOptionDtoCopyWithImpl<$Res>
    implements _$ModifierOptionDtoCopyWith<$Res> {
  __$ModifierOptionDtoCopyWithImpl(this._self, this._then);

  final _ModifierOptionDto _self;
  final $Res Function(_ModifierOptionDto) _then;

/// Create a copy of ModifierOptionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? priceInCents = null,}) {
  return _then(_ModifierOptionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceInCents: null == priceInCents ? _self.priceInCents : priceInCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MenuProductDto {

 String get id; String get name; int get priceInCents; String? get category; List<ModifierOptionDto>? get availableModifiers;
/// Create a copy of MenuProductDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuProductDtoCopyWith<MenuProductDto> get copyWith => _$MenuProductDtoCopyWithImpl<MenuProductDto>(this as MenuProductDto, _$identity);

  /// Serializes this MenuProductDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuProductDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceInCents, priceInCents) || other.priceInCents == priceInCents)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.availableModifiers, availableModifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,priceInCents,category,const DeepCollectionEquality().hash(availableModifiers));

@override
String toString() {
  return 'MenuProductDto(id: $id, name: $name, priceInCents: $priceInCents, category: $category, availableModifiers: $availableModifiers)';
}


}

/// @nodoc
abstract mixin class $MenuProductDtoCopyWith<$Res>  {
  factory $MenuProductDtoCopyWith(MenuProductDto value, $Res Function(MenuProductDto) _then) = _$MenuProductDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int priceInCents, String? category, List<ModifierOptionDto>? availableModifiers
});




}
/// @nodoc
class _$MenuProductDtoCopyWithImpl<$Res>
    implements $MenuProductDtoCopyWith<$Res> {
  _$MenuProductDtoCopyWithImpl(this._self, this._then);

  final MenuProductDto _self;
  final $Res Function(MenuProductDto) _then;

/// Create a copy of MenuProductDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? priceInCents = null,Object? category = freezed,Object? availableModifiers = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceInCents: null == priceInCents ? _self.priceInCents : priceInCents // ignore: cast_nullable_to_non_nullable
as int,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,availableModifiers: freezed == availableModifiers ? _self.availableModifiers : availableModifiers // ignore: cast_nullable_to_non_nullable
as List<ModifierOptionDto>?,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuProductDto].
extension MenuProductDtoPatterns on MenuProductDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuProductDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuProductDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuProductDto value)  $default,){
final _that = this;
switch (_that) {
case _MenuProductDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuProductDto value)?  $default,){
final _that = this;
switch (_that) {
case _MenuProductDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int priceInCents,  String? category,  List<ModifierOptionDto>? availableModifiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuProductDto() when $default != null:
return $default(_that.id,_that.name,_that.priceInCents,_that.category,_that.availableModifiers);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int priceInCents,  String? category,  List<ModifierOptionDto>? availableModifiers)  $default,) {final _that = this;
switch (_that) {
case _MenuProductDto():
return $default(_that.id,_that.name,_that.priceInCents,_that.category,_that.availableModifiers);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int priceInCents,  String? category,  List<ModifierOptionDto>? availableModifiers)?  $default,) {final _that = this;
switch (_that) {
case _MenuProductDto() when $default != null:
return $default(_that.id,_that.name,_that.priceInCents,_that.category,_that.availableModifiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuProductDto implements MenuProductDto {
  const _MenuProductDto({required this.id, required this.name, required this.priceInCents, this.category, final  List<ModifierOptionDto>? availableModifiers = const []}): _availableModifiers = availableModifiers;
  factory _MenuProductDto.fromJson(Map<String, dynamic> json) => _$MenuProductDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  int priceInCents;
@override final  String? category;
 final  List<ModifierOptionDto>? _availableModifiers;
@override@JsonKey() List<ModifierOptionDto>? get availableModifiers {
  final value = _availableModifiers;
  if (value == null) return null;
  if (_availableModifiers is EqualUnmodifiableListView) return _availableModifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of MenuProductDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuProductDtoCopyWith<_MenuProductDto> get copyWith => __$MenuProductDtoCopyWithImpl<_MenuProductDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuProductDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuProductDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceInCents, priceInCents) || other.priceInCents == priceInCents)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._availableModifiers, _availableModifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,priceInCents,category,const DeepCollectionEquality().hash(_availableModifiers));

@override
String toString() {
  return 'MenuProductDto(id: $id, name: $name, priceInCents: $priceInCents, category: $category, availableModifiers: $availableModifiers)';
}


}

/// @nodoc
abstract mixin class _$MenuProductDtoCopyWith<$Res> implements $MenuProductDtoCopyWith<$Res> {
  factory _$MenuProductDtoCopyWith(_MenuProductDto value, $Res Function(_MenuProductDto) _then) = __$MenuProductDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int priceInCents, String? category, List<ModifierOptionDto>? availableModifiers
});




}
/// @nodoc
class __$MenuProductDtoCopyWithImpl<$Res>
    implements _$MenuProductDtoCopyWith<$Res> {
  __$MenuProductDtoCopyWithImpl(this._self, this._then);

  final _MenuProductDto _self;
  final $Res Function(_MenuProductDto) _then;

/// Create a copy of MenuProductDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? priceInCents = null,Object? category = freezed,Object? availableModifiers = freezed,}) {
  return _then(_MenuProductDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceInCents: null == priceInCents ? _self.priceInCents : priceInCents // ignore: cast_nullable_to_non_nullable
as int,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,availableModifiers: freezed == availableModifiers ? _self._availableModifiers : availableModifiers // ignore: cast_nullable_to_non_nullable
as List<ModifierOptionDto>?,
  ));
}


}


/// @nodoc
mixin _$OrderItemDto {

 String get id; MenuProductDto get product; int get quantity; List<ModifierOptionDto>? get selectedModifiers; int? get seatNumber; String get status;
/// Create a copy of OrderItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderItemDtoCopyWith<OrderItemDto> get copyWith => _$OrderItemDtoCopyWithImpl<OrderItemDto>(this as OrderItemDto, _$identity);

  /// Serializes this OrderItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.product, product) || other.product == product)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other.selectedModifiers, selectedModifiers)&&(identical(other.seatNumber, seatNumber) || other.seatNumber == seatNumber)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,product,quantity,const DeepCollectionEquality().hash(selectedModifiers),seatNumber,status);

@override
String toString() {
  return 'OrderItemDto(id: $id, product: $product, quantity: $quantity, selectedModifiers: $selectedModifiers, seatNumber: $seatNumber, status: $status)';
}


}

/// @nodoc
abstract mixin class $OrderItemDtoCopyWith<$Res>  {
  factory $OrderItemDtoCopyWith(OrderItemDto value, $Res Function(OrderItemDto) _then) = _$OrderItemDtoCopyWithImpl;
@useResult
$Res call({
 String id, MenuProductDto product, int quantity, List<ModifierOptionDto>? selectedModifiers, int? seatNumber, String status
});


$MenuProductDtoCopyWith<$Res> get product;

}
/// @nodoc
class _$OrderItemDtoCopyWithImpl<$Res>
    implements $OrderItemDtoCopyWith<$Res> {
  _$OrderItemDtoCopyWithImpl(this._self, this._then);

  final OrderItemDto _self;
  final $Res Function(OrderItemDto) _then;

/// Create a copy of OrderItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? product = null,Object? quantity = null,Object? selectedModifiers = freezed,Object? seatNumber = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as MenuProductDto,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selectedModifiers: freezed == selectedModifiers ? _self.selectedModifiers : selectedModifiers // ignore: cast_nullable_to_non_nullable
as List<ModifierOptionDto>?,seatNumber: freezed == seatNumber ? _self.seatNumber : seatNumber // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of OrderItemDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuProductDtoCopyWith<$Res> get product {
  
  return $MenuProductDtoCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderItemDto].
extension OrderItemDtoPatterns on OrderItemDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderItemDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderItemDto value)  $default,){
final _that = this;
switch (_that) {
case _OrderItemDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _OrderItemDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MenuProductDto product,  int quantity,  List<ModifierOptionDto>? selectedModifiers,  int? seatNumber,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderItemDto() when $default != null:
return $default(_that.id,_that.product,_that.quantity,_that.selectedModifiers,_that.seatNumber,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MenuProductDto product,  int quantity,  List<ModifierOptionDto>? selectedModifiers,  int? seatNumber,  String status)  $default,) {final _that = this;
switch (_that) {
case _OrderItemDto():
return $default(_that.id,_that.product,_that.quantity,_that.selectedModifiers,_that.seatNumber,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MenuProductDto product,  int quantity,  List<ModifierOptionDto>? selectedModifiers,  int? seatNumber,  String status)?  $default,) {final _that = this;
switch (_that) {
case _OrderItemDto() when $default != null:
return $default(_that.id,_that.product,_that.quantity,_that.selectedModifiers,_that.seatNumber,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderItemDto implements OrderItemDto {
  const _OrderItemDto({required this.id, required this.product, required this.quantity, final  List<ModifierOptionDto>? selectedModifiers = const [], this.seatNumber, required this.status}): _selectedModifiers = selectedModifiers;
  factory _OrderItemDto.fromJson(Map<String, dynamic> json) => _$OrderItemDtoFromJson(json);

@override final  String id;
@override final  MenuProductDto product;
@override final  int quantity;
 final  List<ModifierOptionDto>? _selectedModifiers;
@override@JsonKey() List<ModifierOptionDto>? get selectedModifiers {
  final value = _selectedModifiers;
  if (value == null) return null;
  if (_selectedModifiers is EqualUnmodifiableListView) return _selectedModifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? seatNumber;
@override final  String status;

/// Create a copy of OrderItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderItemDtoCopyWith<_OrderItemDto> get copyWith => __$OrderItemDtoCopyWithImpl<_OrderItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.product, product) || other.product == product)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other._selectedModifiers, _selectedModifiers)&&(identical(other.seatNumber, seatNumber) || other.seatNumber == seatNumber)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,product,quantity,const DeepCollectionEquality().hash(_selectedModifiers),seatNumber,status);

@override
String toString() {
  return 'OrderItemDto(id: $id, product: $product, quantity: $quantity, selectedModifiers: $selectedModifiers, seatNumber: $seatNumber, status: $status)';
}


}

/// @nodoc
abstract mixin class _$OrderItemDtoCopyWith<$Res> implements $OrderItemDtoCopyWith<$Res> {
  factory _$OrderItemDtoCopyWith(_OrderItemDto value, $Res Function(_OrderItemDto) _then) = __$OrderItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, MenuProductDto product, int quantity, List<ModifierOptionDto>? selectedModifiers, int? seatNumber, String status
});


@override $MenuProductDtoCopyWith<$Res> get product;

}
/// @nodoc
class __$OrderItemDtoCopyWithImpl<$Res>
    implements _$OrderItemDtoCopyWith<$Res> {
  __$OrderItemDtoCopyWithImpl(this._self, this._then);

  final _OrderItemDto _self;
  final $Res Function(_OrderItemDto) _then;

/// Create a copy of OrderItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? product = null,Object? quantity = null,Object? selectedModifiers = freezed,Object? seatNumber = freezed,Object? status = null,}) {
  return _then(_OrderItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as MenuProductDto,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selectedModifiers: freezed == selectedModifiers ? _self._selectedModifiers : selectedModifiers // ignore: cast_nullable_to_non_nullable
as List<ModifierOptionDto>?,seatNumber: freezed == seatNumber ? _self.seatNumber : seatNumber // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of OrderItemDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuProductDtoCopyWith<$Res> get product {
  
  return $MenuProductDtoCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// @nodoc
mixin _$OrderDto {

 String get id; String? get tableId; List<OrderItemDto> get items; String get status; String get createdAt; String? get updatedAt; String? get waiterName; List<String>? get cancelLogs;
/// Create a copy of OrderDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDtoCopyWith<OrderDto> get copyWith => _$OrderDtoCopyWithImpl<OrderDto>(this as OrderDto, _$identity);

  /// Serializes this OrderDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.waiterName, waiterName) || other.waiterName == waiterName)&&const DeepCollectionEquality().equals(other.cancelLogs, cancelLogs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableId,const DeepCollectionEquality().hash(items),status,createdAt,updatedAt,waiterName,const DeepCollectionEquality().hash(cancelLogs));

@override
String toString() {
  return 'OrderDto(id: $id, tableId: $tableId, items: $items, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, waiterName: $waiterName, cancelLogs: $cancelLogs)';
}


}

/// @nodoc
abstract mixin class $OrderDtoCopyWith<$Res>  {
  factory $OrderDtoCopyWith(OrderDto value, $Res Function(OrderDto) _then) = _$OrderDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? tableId, List<OrderItemDto> items, String status, String createdAt, String? updatedAt, String? waiterName, List<String>? cancelLogs
});




}
/// @nodoc
class _$OrderDtoCopyWithImpl<$Res>
    implements $OrderDtoCopyWith<$Res> {
  _$OrderDtoCopyWithImpl(this._self, this._then);

  final OrderDto _self;
  final $Res Function(OrderDto) _then;

/// Create a copy of OrderDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tableId = freezed,Object? items = null,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,Object? waiterName = freezed,Object? cancelLogs = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItemDto>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,waiterName: freezed == waiterName ? _self.waiterName : waiterName // ignore: cast_nullable_to_non_nullable
as String?,cancelLogs: freezed == cancelLogs ? _self.cancelLogs : cancelLogs // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderDto].
extension OrderDtoPatterns on OrderDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderDto value)  $default,){
final _that = this;
switch (_that) {
case _OrderDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderDto value)?  $default,){
final _that = this;
switch (_that) {
case _OrderDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? tableId,  List<OrderItemDto> items,  String status,  String createdAt,  String? updatedAt,  String? waiterName,  List<String>? cancelLogs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderDto() when $default != null:
return $default(_that.id,_that.tableId,_that.items,_that.status,_that.createdAt,_that.updatedAt,_that.waiterName,_that.cancelLogs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? tableId,  List<OrderItemDto> items,  String status,  String createdAt,  String? updatedAt,  String? waiterName,  List<String>? cancelLogs)  $default,) {final _that = this;
switch (_that) {
case _OrderDto():
return $default(_that.id,_that.tableId,_that.items,_that.status,_that.createdAt,_that.updatedAt,_that.waiterName,_that.cancelLogs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? tableId,  List<OrderItemDto> items,  String status,  String createdAt,  String? updatedAt,  String? waiterName,  List<String>? cancelLogs)?  $default,) {final _that = this;
switch (_that) {
case _OrderDto() when $default != null:
return $default(_that.id,_that.tableId,_that.items,_that.status,_that.createdAt,_that.updatedAt,_that.waiterName,_that.cancelLogs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderDto implements OrderDto {
  const _OrderDto({required this.id, this.tableId, required final  List<OrderItemDto> items, required this.status, required this.createdAt, this.updatedAt, this.waiterName, final  List<String>? cancelLogs = const []}): _items = items,_cancelLogs = cancelLogs;
  factory _OrderDto.fromJson(Map<String, dynamic> json) => _$OrderDtoFromJson(json);

@override final  String id;
@override final  String? tableId;
 final  List<OrderItemDto> _items;
@override List<OrderItemDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String status;
@override final  String createdAt;
@override final  String? updatedAt;
@override final  String? waiterName;
 final  List<String>? _cancelLogs;
@override@JsonKey() List<String>? get cancelLogs {
  final value = _cancelLogs;
  if (value == null) return null;
  if (_cancelLogs is EqualUnmodifiableListView) return _cancelLogs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of OrderDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderDtoCopyWith<_OrderDto> get copyWith => __$OrderDtoCopyWithImpl<_OrderDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.waiterName, waiterName) || other.waiterName == waiterName)&&const DeepCollectionEquality().equals(other._cancelLogs, _cancelLogs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableId,const DeepCollectionEquality().hash(_items),status,createdAt,updatedAt,waiterName,const DeepCollectionEquality().hash(_cancelLogs));

@override
String toString() {
  return 'OrderDto(id: $id, tableId: $tableId, items: $items, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, waiterName: $waiterName, cancelLogs: $cancelLogs)';
}


}

/// @nodoc
abstract mixin class _$OrderDtoCopyWith<$Res> implements $OrderDtoCopyWith<$Res> {
  factory _$OrderDtoCopyWith(_OrderDto value, $Res Function(_OrderDto) _then) = __$OrderDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? tableId, List<OrderItemDto> items, String status, String createdAt, String? updatedAt, String? waiterName, List<String>? cancelLogs
});




}
/// @nodoc
class __$OrderDtoCopyWithImpl<$Res>
    implements _$OrderDtoCopyWith<$Res> {
  __$OrderDtoCopyWithImpl(this._self, this._then);

  final _OrderDto _self;
  final $Res Function(_OrderDto) _then;

/// Create a copy of OrderDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tableId = freezed,Object? items = null,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,Object? waiterName = freezed,Object? cancelLogs = freezed,}) {
  return _then(_OrderDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItemDto>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,waiterName: freezed == waiterName ? _self.waiterName : waiterName // ignore: cast_nullable_to_non_nullable
as String?,cancelLogs: freezed == cancelLogs ? _self._cancelLogs : cancelLogs // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
