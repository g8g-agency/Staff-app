// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuestSeatDto {

@JsonKey(name: 'seat_number') int get seatNumber;@JsonKey(name: 'guest_name') String? get guestName;@JsonKey(name: 'ordered_item_ids') List<String> get orderedItemIds;
/// Create a copy of GuestSeatDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestSeatDtoCopyWith<GuestSeatDto> get copyWith => _$GuestSeatDtoCopyWithImpl<GuestSeatDto>(this as GuestSeatDto, _$identity);

  /// Serializes this GuestSeatDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestSeatDto&&(identical(other.seatNumber, seatNumber) || other.seatNumber == seatNumber)&&(identical(other.guestName, guestName) || other.guestName == guestName)&&const DeepCollectionEquality().equals(other.orderedItemIds, orderedItemIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seatNumber,guestName,const DeepCollectionEquality().hash(orderedItemIds));

@override
String toString() {
  return 'GuestSeatDto(seatNumber: $seatNumber, guestName: $guestName, orderedItemIds: $orderedItemIds)';
}


}

/// @nodoc
abstract mixin class $GuestSeatDtoCopyWith<$Res>  {
  factory $GuestSeatDtoCopyWith(GuestSeatDto value, $Res Function(GuestSeatDto) _then) = _$GuestSeatDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'seat_number') int seatNumber,@JsonKey(name: 'guest_name') String? guestName,@JsonKey(name: 'ordered_item_ids') List<String> orderedItemIds
});




}
/// @nodoc
class _$GuestSeatDtoCopyWithImpl<$Res>
    implements $GuestSeatDtoCopyWith<$Res> {
  _$GuestSeatDtoCopyWithImpl(this._self, this._then);

  final GuestSeatDto _self;
  final $Res Function(GuestSeatDto) _then;

/// Create a copy of GuestSeatDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seatNumber = null,Object? guestName = freezed,Object? orderedItemIds = null,}) {
  return _then(_self.copyWith(
seatNumber: null == seatNumber ? _self.seatNumber : seatNumber // ignore: cast_nullable_to_non_nullable
as int,guestName: freezed == guestName ? _self.guestName : guestName // ignore: cast_nullable_to_non_nullable
as String?,orderedItemIds: null == orderedItemIds ? _self.orderedItemIds : orderedItemIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestSeatDto].
extension GuestSeatDtoPatterns on GuestSeatDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestSeatDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestSeatDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestSeatDto value)  $default,){
final _that = this;
switch (_that) {
case _GuestSeatDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestSeatDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuestSeatDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'seat_number')  int seatNumber, @JsonKey(name: 'guest_name')  String? guestName, @JsonKey(name: 'ordered_item_ids')  List<String> orderedItemIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestSeatDto() when $default != null:
return $default(_that.seatNumber,_that.guestName,_that.orderedItemIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'seat_number')  int seatNumber, @JsonKey(name: 'guest_name')  String? guestName, @JsonKey(name: 'ordered_item_ids')  List<String> orderedItemIds)  $default,) {final _that = this;
switch (_that) {
case _GuestSeatDto():
return $default(_that.seatNumber,_that.guestName,_that.orderedItemIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'seat_number')  int seatNumber, @JsonKey(name: 'guest_name')  String? guestName, @JsonKey(name: 'ordered_item_ids')  List<String> orderedItemIds)?  $default,) {final _that = this;
switch (_that) {
case _GuestSeatDto() when $default != null:
return $default(_that.seatNumber,_that.guestName,_that.orderedItemIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestSeatDto implements GuestSeatDto {
  const _GuestSeatDto({@JsonKey(name: 'seat_number') required this.seatNumber, @JsonKey(name: 'guest_name') this.guestName, @JsonKey(name: 'ordered_item_ids') final  List<String> orderedItemIds = const []}): _orderedItemIds = orderedItemIds;
  factory _GuestSeatDto.fromJson(Map<String, dynamic> json) => _$GuestSeatDtoFromJson(json);

@override@JsonKey(name: 'seat_number') final  int seatNumber;
@override@JsonKey(name: 'guest_name') final  String? guestName;
 final  List<String> _orderedItemIds;
@override@JsonKey(name: 'ordered_item_ids') List<String> get orderedItemIds {
  if (_orderedItemIds is EqualUnmodifiableListView) return _orderedItemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orderedItemIds);
}


/// Create a copy of GuestSeatDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestSeatDtoCopyWith<_GuestSeatDto> get copyWith => __$GuestSeatDtoCopyWithImpl<_GuestSeatDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestSeatDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestSeatDto&&(identical(other.seatNumber, seatNumber) || other.seatNumber == seatNumber)&&(identical(other.guestName, guestName) || other.guestName == guestName)&&const DeepCollectionEquality().equals(other._orderedItemIds, _orderedItemIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seatNumber,guestName,const DeepCollectionEquality().hash(_orderedItemIds));

@override
String toString() {
  return 'GuestSeatDto(seatNumber: $seatNumber, guestName: $guestName, orderedItemIds: $orderedItemIds)';
}


}

/// @nodoc
abstract mixin class _$GuestSeatDtoCopyWith<$Res> implements $GuestSeatDtoCopyWith<$Res> {
  factory _$GuestSeatDtoCopyWith(_GuestSeatDto value, $Res Function(_GuestSeatDto) _then) = __$GuestSeatDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'seat_number') int seatNumber,@JsonKey(name: 'guest_name') String? guestName,@JsonKey(name: 'ordered_item_ids') List<String> orderedItemIds
});




}
/// @nodoc
class __$GuestSeatDtoCopyWithImpl<$Res>
    implements _$GuestSeatDtoCopyWith<$Res> {
  __$GuestSeatDtoCopyWithImpl(this._self, this._then);

  final _GuestSeatDto _self;
  final $Res Function(_GuestSeatDto) _then;

/// Create a copy of GuestSeatDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seatNumber = null,Object? guestName = freezed,Object? orderedItemIds = null,}) {
  return _then(_GuestSeatDto(
seatNumber: null == seatNumber ? _self.seatNumber : seatNumber // ignore: cast_nullable_to_non_nullable
as int,guestName: freezed == guestName ? _self.guestName : guestName // ignore: cast_nullable_to_non_nullable
as String?,orderedItemIds: null == orderedItemIds ? _self._orderedItemIds : orderedItemIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$TableDto {

 String get id; String get label; int get capacity; String get status;@JsonKey(name: 'active_order_id') String? get activeOrderId;@JsonKey(name: 'occupied_seats') List<GuestSeatDto> get occupiedSeats;@JsonKey(name: 'merged_table_ids') List<String> get mergedTableIds;@JsonKey(name: 'version_num') int get versionNum;
/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableDtoCopyWith<TableDto> get copyWith => _$TableDtoCopyWithImpl<TableDto>(this as TableDto, _$identity);

  /// Serializes this TableDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.status, status) || other.status == status)&&(identical(other.activeOrderId, activeOrderId) || other.activeOrderId == activeOrderId)&&const DeepCollectionEquality().equals(other.occupiedSeats, occupiedSeats)&&const DeepCollectionEquality().equals(other.mergedTableIds, mergedTableIds)&&(identical(other.versionNum, versionNum) || other.versionNum == versionNum));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,capacity,status,activeOrderId,const DeepCollectionEquality().hash(occupiedSeats),const DeepCollectionEquality().hash(mergedTableIds),versionNum);

@override
String toString() {
  return 'TableDto(id: $id, label: $label, capacity: $capacity, status: $status, activeOrderId: $activeOrderId, occupiedSeats: $occupiedSeats, mergedTableIds: $mergedTableIds, versionNum: $versionNum)';
}


}

/// @nodoc
abstract mixin class $TableDtoCopyWith<$Res>  {
  factory $TableDtoCopyWith(TableDto value, $Res Function(TableDto) _then) = _$TableDtoCopyWithImpl;
@useResult
$Res call({
 String id, String label, int capacity, String status,@JsonKey(name: 'active_order_id') String? activeOrderId,@JsonKey(name: 'occupied_seats') List<GuestSeatDto> occupiedSeats,@JsonKey(name: 'merged_table_ids') List<String> mergedTableIds,@JsonKey(name: 'version_num') int versionNum
});




}
/// @nodoc
class _$TableDtoCopyWithImpl<$Res>
    implements $TableDtoCopyWith<$Res> {
  _$TableDtoCopyWithImpl(this._self, this._then);

  final TableDto _self;
  final $Res Function(TableDto) _then;

/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? capacity = null,Object? status = null,Object? activeOrderId = freezed,Object? occupiedSeats = null,Object? mergedTableIds = null,Object? versionNum = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,activeOrderId: freezed == activeOrderId ? _self.activeOrderId : activeOrderId // ignore: cast_nullable_to_non_nullable
as String?,occupiedSeats: null == occupiedSeats ? _self.occupiedSeats : occupiedSeats // ignore: cast_nullable_to_non_nullable
as List<GuestSeatDto>,mergedTableIds: null == mergedTableIds ? _self.mergedTableIds : mergedTableIds // ignore: cast_nullable_to_non_nullable
as List<String>,versionNum: null == versionNum ? _self.versionNum : versionNum // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TableDto].
extension TableDtoPatterns on TableDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TableDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TableDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TableDto value)  $default,){
final _that = this;
switch (_that) {
case _TableDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TableDto value)?  $default,){
final _that = this;
switch (_that) {
case _TableDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  int capacity,  String status, @JsonKey(name: 'active_order_id')  String? activeOrderId, @JsonKey(name: 'occupied_seats')  List<GuestSeatDto> occupiedSeats, @JsonKey(name: 'merged_table_ids')  List<String> mergedTableIds, @JsonKey(name: 'version_num')  int versionNum)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TableDto() when $default != null:
return $default(_that.id,_that.label,_that.capacity,_that.status,_that.activeOrderId,_that.occupiedSeats,_that.mergedTableIds,_that.versionNum);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  int capacity,  String status, @JsonKey(name: 'active_order_id')  String? activeOrderId, @JsonKey(name: 'occupied_seats')  List<GuestSeatDto> occupiedSeats, @JsonKey(name: 'merged_table_ids')  List<String> mergedTableIds, @JsonKey(name: 'version_num')  int versionNum)  $default,) {final _that = this;
switch (_that) {
case _TableDto():
return $default(_that.id,_that.label,_that.capacity,_that.status,_that.activeOrderId,_that.occupiedSeats,_that.mergedTableIds,_that.versionNum);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  int capacity,  String status, @JsonKey(name: 'active_order_id')  String? activeOrderId, @JsonKey(name: 'occupied_seats')  List<GuestSeatDto> occupiedSeats, @JsonKey(name: 'merged_table_ids')  List<String> mergedTableIds, @JsonKey(name: 'version_num')  int versionNum)?  $default,) {final _that = this;
switch (_that) {
case _TableDto() when $default != null:
return $default(_that.id,_that.label,_that.capacity,_that.status,_that.activeOrderId,_that.occupiedSeats,_that.mergedTableIds,_that.versionNum);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TableDto extends TableDto {
  const _TableDto({required this.id, required this.label, required this.capacity, required this.status, @JsonKey(name: 'active_order_id') this.activeOrderId, @JsonKey(name: 'occupied_seats') final  List<GuestSeatDto> occupiedSeats = const [], @JsonKey(name: 'merged_table_ids') final  List<String> mergedTableIds = const [], @JsonKey(name: 'version_num') this.versionNum = 1}): _occupiedSeats = occupiedSeats,_mergedTableIds = mergedTableIds,super._();
  factory _TableDto.fromJson(Map<String, dynamic> json) => _$TableDtoFromJson(json);

@override final  String id;
@override final  String label;
@override final  int capacity;
@override final  String status;
@override@JsonKey(name: 'active_order_id') final  String? activeOrderId;
 final  List<GuestSeatDto> _occupiedSeats;
@override@JsonKey(name: 'occupied_seats') List<GuestSeatDto> get occupiedSeats {
  if (_occupiedSeats is EqualUnmodifiableListView) return _occupiedSeats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_occupiedSeats);
}

 final  List<String> _mergedTableIds;
@override@JsonKey(name: 'merged_table_ids') List<String> get mergedTableIds {
  if (_mergedTableIds is EqualUnmodifiableListView) return _mergedTableIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mergedTableIds);
}

@override@JsonKey(name: 'version_num') final  int versionNum;

/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TableDtoCopyWith<_TableDto> get copyWith => __$TableDtoCopyWithImpl<_TableDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TableDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TableDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.status, status) || other.status == status)&&(identical(other.activeOrderId, activeOrderId) || other.activeOrderId == activeOrderId)&&const DeepCollectionEquality().equals(other._occupiedSeats, _occupiedSeats)&&const DeepCollectionEquality().equals(other._mergedTableIds, _mergedTableIds)&&(identical(other.versionNum, versionNum) || other.versionNum == versionNum));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,capacity,status,activeOrderId,const DeepCollectionEquality().hash(_occupiedSeats),const DeepCollectionEquality().hash(_mergedTableIds),versionNum);

@override
String toString() {
  return 'TableDto(id: $id, label: $label, capacity: $capacity, status: $status, activeOrderId: $activeOrderId, occupiedSeats: $occupiedSeats, mergedTableIds: $mergedTableIds, versionNum: $versionNum)';
}


}

/// @nodoc
abstract mixin class _$TableDtoCopyWith<$Res> implements $TableDtoCopyWith<$Res> {
  factory _$TableDtoCopyWith(_TableDto value, $Res Function(_TableDto) _then) = __$TableDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, int capacity, String status,@JsonKey(name: 'active_order_id') String? activeOrderId,@JsonKey(name: 'occupied_seats') List<GuestSeatDto> occupiedSeats,@JsonKey(name: 'merged_table_ids') List<String> mergedTableIds,@JsonKey(name: 'version_num') int versionNum
});




}
/// @nodoc
class __$TableDtoCopyWithImpl<$Res>
    implements _$TableDtoCopyWith<$Res> {
  __$TableDtoCopyWithImpl(this._self, this._then);

  final _TableDto _self;
  final $Res Function(_TableDto) _then;

/// Create a copy of TableDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? capacity = null,Object? status = null,Object? activeOrderId = freezed,Object? occupiedSeats = null,Object? mergedTableIds = null,Object? versionNum = null,}) {
  return _then(_TableDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,activeOrderId: freezed == activeOrderId ? _self.activeOrderId : activeOrderId // ignore: cast_nullable_to_non_nullable
as String?,occupiedSeats: null == occupiedSeats ? _self._occupiedSeats : occupiedSeats // ignore: cast_nullable_to_non_nullable
as List<GuestSeatDto>,mergedTableIds: null == mergedTableIds ? _self._mergedTableIds : mergedTableIds // ignore: cast_nullable_to_non_nullable
as List<String>,versionNum: null == versionNum ? _self.versionNum : versionNum // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
