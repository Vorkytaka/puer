// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'counter_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CounterEffect {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadCounter,
    required TResult Function(int value) saveCounter,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadCounter,
    TResult? Function(int value)? saveCounter,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadCounter,
    TResult Function(int value)? saveCounter,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadCounterEffect value) loadCounter,
    required TResult Function(SaveCounterEffect value) saveCounter,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadCounterEffect value)? loadCounter,
    TResult? Function(SaveCounterEffect value)? saveCounter,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadCounterEffect value)? loadCounter,
    TResult Function(SaveCounterEffect value)? saveCounter,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CounterEffectCopyWith<$Res> {
  factory $CounterEffectCopyWith(
    CounterEffect value,
    $Res Function(CounterEffect) then,
  ) = _$CounterEffectCopyWithImpl<$Res, CounterEffect>;
}

/// @nodoc
class _$CounterEffectCopyWithImpl<$Res, $Val extends CounterEffect>
    implements $CounterEffectCopyWith<$Res> {
  _$CounterEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CounterEffect
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadCounterEffectImplCopyWith<$Res> {
  factory _$$LoadCounterEffectImplCopyWith(
    _$LoadCounterEffectImpl value,
    $Res Function(_$LoadCounterEffectImpl) then,
  ) = __$$LoadCounterEffectImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadCounterEffectImplCopyWithImpl<$Res>
    extends _$CounterEffectCopyWithImpl<$Res, _$LoadCounterEffectImpl>
    implements _$$LoadCounterEffectImplCopyWith<$Res> {
  __$$LoadCounterEffectImplCopyWithImpl(
    _$LoadCounterEffectImpl _value,
    $Res Function(_$LoadCounterEffectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CounterEffect
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadCounterEffectImpl implements LoadCounterEffect {
  const _$LoadCounterEffectImpl();

  @override
  String toString() {
    return 'CounterEffect.loadCounter()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadCounterEffectImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadCounter,
    required TResult Function(int value) saveCounter,
  }) {
    return loadCounter();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadCounter,
    TResult? Function(int value)? saveCounter,
  }) {
    return loadCounter?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadCounter,
    TResult Function(int value)? saveCounter,
    required TResult orElse(),
  }) {
    if (loadCounter != null) {
      return loadCounter();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadCounterEffect value) loadCounter,
    required TResult Function(SaveCounterEffect value) saveCounter,
  }) {
    return loadCounter(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadCounterEffect value)? loadCounter,
    TResult? Function(SaveCounterEffect value)? saveCounter,
  }) {
    return loadCounter?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadCounterEffect value)? loadCounter,
    TResult Function(SaveCounterEffect value)? saveCounter,
    required TResult orElse(),
  }) {
    if (loadCounter != null) {
      return loadCounter(this);
    }
    return orElse();
  }
}

abstract class LoadCounterEffect implements CounterEffect {
  const factory LoadCounterEffect() = _$LoadCounterEffectImpl;
}

/// @nodoc
abstract class _$$SaveCounterEffectImplCopyWith<$Res> {
  factory _$$SaveCounterEffectImplCopyWith(
    _$SaveCounterEffectImpl value,
    $Res Function(_$SaveCounterEffectImpl) then,
  ) = __$$SaveCounterEffectImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int value});
}

/// @nodoc
class __$$SaveCounterEffectImplCopyWithImpl<$Res>
    extends _$CounterEffectCopyWithImpl<$Res, _$SaveCounterEffectImpl>
    implements _$$SaveCounterEffectImplCopyWith<$Res> {
  __$$SaveCounterEffectImplCopyWithImpl(
    _$SaveCounterEffectImpl _value,
    $Res Function(_$SaveCounterEffectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CounterEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? value = null}) {
    return _then(
      _$SaveCounterEffectImpl(
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$SaveCounterEffectImpl implements SaveCounterEffect {
  const _$SaveCounterEffectImpl({required this.value});

  @override
  final int value;

  @override
  String toString() {
    return 'CounterEffect.saveCounter(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaveCounterEffectImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of CounterEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaveCounterEffectImplCopyWith<_$SaveCounterEffectImpl> get copyWith =>
      __$$SaveCounterEffectImplCopyWithImpl<_$SaveCounterEffectImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadCounter,
    required TResult Function(int value) saveCounter,
  }) {
    return saveCounter(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadCounter,
    TResult? Function(int value)? saveCounter,
  }) {
    return saveCounter?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadCounter,
    TResult Function(int value)? saveCounter,
    required TResult orElse(),
  }) {
    if (saveCounter != null) {
      return saveCounter(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadCounterEffect value) loadCounter,
    required TResult Function(SaveCounterEffect value) saveCounter,
  }) {
    return saveCounter(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadCounterEffect value)? loadCounter,
    TResult? Function(SaveCounterEffect value)? saveCounter,
  }) {
    return saveCounter?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadCounterEffect value)? loadCounter,
    TResult Function(SaveCounterEffect value)? saveCounter,
    required TResult orElse(),
  }) {
    if (saveCounter != null) {
      return saveCounter(this);
    }
    return orElse();
  }
}

abstract class SaveCounterEffect implements CounterEffect {
  const factory SaveCounterEffect({required final int value}) =
      _$SaveCounterEffectImpl;

  int get value;

  /// Create a copy of CounterEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaveCounterEffectImplCopyWith<_$SaveCounterEffectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
