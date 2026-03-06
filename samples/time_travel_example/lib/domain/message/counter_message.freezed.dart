// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'counter_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CounterMessage {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() increment,
    required TResult Function() decrement,
    required TResult Function() requestLoading,
    required TResult Function(int value) loadSuccessful,
    required TResult Function() loadFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? increment,
    TResult? Function()? decrement,
    TResult? Function()? requestLoading,
    TResult? Function(int value)? loadSuccessful,
    TResult? Function()? loadFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? increment,
    TResult Function()? decrement,
    TResult Function()? requestLoading,
    TResult Function(int value)? loadSuccessful,
    TResult Function()? loadFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IncrementMessage value) increment,
    required TResult Function(DecrementMessage value) decrement,
    required TResult Function(RequestLoadingMessage value) requestLoading,
    required TResult Function(LoadSuccessfulMessage value) loadSuccessful,
    required TResult Function(LoadFailedMessage value) loadFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IncrementMessage value)? increment,
    TResult? Function(DecrementMessage value)? decrement,
    TResult? Function(RequestLoadingMessage value)? requestLoading,
    TResult? Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult? Function(LoadFailedMessage value)? loadFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IncrementMessage value)? increment,
    TResult Function(DecrementMessage value)? decrement,
    TResult Function(RequestLoadingMessage value)? requestLoading,
    TResult Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult Function(LoadFailedMessage value)? loadFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CounterMessageCopyWith<$Res> {
  factory $CounterMessageCopyWith(
    CounterMessage value,
    $Res Function(CounterMessage) then,
  ) = _$CounterMessageCopyWithImpl<$Res, CounterMessage>;
}

/// @nodoc
class _$CounterMessageCopyWithImpl<$Res, $Val extends CounterMessage>
    implements $CounterMessageCopyWith<$Res> {
  _$CounterMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$IncrementMessageImplCopyWith<$Res> {
  factory _$$IncrementMessageImplCopyWith(
    _$IncrementMessageImpl value,
    $Res Function(_$IncrementMessageImpl) then,
  ) = __$$IncrementMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IncrementMessageImplCopyWithImpl<$Res>
    extends _$CounterMessageCopyWithImpl<$Res, _$IncrementMessageImpl>
    implements _$$IncrementMessageImplCopyWith<$Res> {
  __$$IncrementMessageImplCopyWithImpl(
    _$IncrementMessageImpl _value,
    $Res Function(_$IncrementMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$IncrementMessageImpl implements IncrementMessage {
  const _$IncrementMessageImpl();

  @override
  String toString() {
    return 'CounterMessage.increment()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IncrementMessageImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() increment,
    required TResult Function() decrement,
    required TResult Function() requestLoading,
    required TResult Function(int value) loadSuccessful,
    required TResult Function() loadFailed,
  }) {
    return increment();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? increment,
    TResult? Function()? decrement,
    TResult? Function()? requestLoading,
    TResult? Function(int value)? loadSuccessful,
    TResult? Function()? loadFailed,
  }) {
    return increment?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? increment,
    TResult Function()? decrement,
    TResult Function()? requestLoading,
    TResult Function(int value)? loadSuccessful,
    TResult Function()? loadFailed,
    required TResult orElse(),
  }) {
    if (increment != null) {
      return increment();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IncrementMessage value) increment,
    required TResult Function(DecrementMessage value) decrement,
    required TResult Function(RequestLoadingMessage value) requestLoading,
    required TResult Function(LoadSuccessfulMessage value) loadSuccessful,
    required TResult Function(LoadFailedMessage value) loadFailed,
  }) {
    return increment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IncrementMessage value)? increment,
    TResult? Function(DecrementMessage value)? decrement,
    TResult? Function(RequestLoadingMessage value)? requestLoading,
    TResult? Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult? Function(LoadFailedMessage value)? loadFailed,
  }) {
    return increment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IncrementMessage value)? increment,
    TResult Function(DecrementMessage value)? decrement,
    TResult Function(RequestLoadingMessage value)? requestLoading,
    TResult Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult Function(LoadFailedMessage value)? loadFailed,
    required TResult orElse(),
  }) {
    if (increment != null) {
      return increment(this);
    }
    return orElse();
  }
}

abstract class IncrementMessage implements CounterMessage {
  const factory IncrementMessage() = _$IncrementMessageImpl;
}

/// @nodoc
abstract class _$$DecrementMessageImplCopyWith<$Res> {
  factory _$$DecrementMessageImplCopyWith(
    _$DecrementMessageImpl value,
    $Res Function(_$DecrementMessageImpl) then,
  ) = __$$DecrementMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DecrementMessageImplCopyWithImpl<$Res>
    extends _$CounterMessageCopyWithImpl<$Res, _$DecrementMessageImpl>
    implements _$$DecrementMessageImplCopyWith<$Res> {
  __$$DecrementMessageImplCopyWithImpl(
    _$DecrementMessageImpl _value,
    $Res Function(_$DecrementMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DecrementMessageImpl implements DecrementMessage {
  const _$DecrementMessageImpl();

  @override
  String toString() {
    return 'CounterMessage.decrement()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$DecrementMessageImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() increment,
    required TResult Function() decrement,
    required TResult Function() requestLoading,
    required TResult Function(int value) loadSuccessful,
    required TResult Function() loadFailed,
  }) {
    return decrement();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? increment,
    TResult? Function()? decrement,
    TResult? Function()? requestLoading,
    TResult? Function(int value)? loadSuccessful,
    TResult? Function()? loadFailed,
  }) {
    return decrement?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? increment,
    TResult Function()? decrement,
    TResult Function()? requestLoading,
    TResult Function(int value)? loadSuccessful,
    TResult Function()? loadFailed,
    required TResult orElse(),
  }) {
    if (decrement != null) {
      return decrement();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IncrementMessage value) increment,
    required TResult Function(DecrementMessage value) decrement,
    required TResult Function(RequestLoadingMessage value) requestLoading,
    required TResult Function(LoadSuccessfulMessage value) loadSuccessful,
    required TResult Function(LoadFailedMessage value) loadFailed,
  }) {
    return decrement(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IncrementMessage value)? increment,
    TResult? Function(DecrementMessage value)? decrement,
    TResult? Function(RequestLoadingMessage value)? requestLoading,
    TResult? Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult? Function(LoadFailedMessage value)? loadFailed,
  }) {
    return decrement?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IncrementMessage value)? increment,
    TResult Function(DecrementMessage value)? decrement,
    TResult Function(RequestLoadingMessage value)? requestLoading,
    TResult Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult Function(LoadFailedMessage value)? loadFailed,
    required TResult orElse(),
  }) {
    if (decrement != null) {
      return decrement(this);
    }
    return orElse();
  }
}

abstract class DecrementMessage implements CounterMessage {
  const factory DecrementMessage() = _$DecrementMessageImpl;
}

/// @nodoc
abstract class _$$RequestLoadingMessageImplCopyWith<$Res> {
  factory _$$RequestLoadingMessageImplCopyWith(
    _$RequestLoadingMessageImpl value,
    $Res Function(_$RequestLoadingMessageImpl) then,
  ) = __$$RequestLoadingMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RequestLoadingMessageImplCopyWithImpl<$Res>
    extends _$CounterMessageCopyWithImpl<$Res, _$RequestLoadingMessageImpl>
    implements _$$RequestLoadingMessageImplCopyWith<$Res> {
  __$$RequestLoadingMessageImplCopyWithImpl(
    _$RequestLoadingMessageImpl _value,
    $Res Function(_$RequestLoadingMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$RequestLoadingMessageImpl implements RequestLoadingMessage {
  const _$RequestLoadingMessageImpl();

  @override
  String toString() {
    return 'CounterMessage.requestLoading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestLoadingMessageImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() increment,
    required TResult Function() decrement,
    required TResult Function() requestLoading,
    required TResult Function(int value) loadSuccessful,
    required TResult Function() loadFailed,
  }) {
    return requestLoading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? increment,
    TResult? Function()? decrement,
    TResult? Function()? requestLoading,
    TResult? Function(int value)? loadSuccessful,
    TResult? Function()? loadFailed,
  }) {
    return requestLoading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? increment,
    TResult Function()? decrement,
    TResult Function()? requestLoading,
    TResult Function(int value)? loadSuccessful,
    TResult Function()? loadFailed,
    required TResult orElse(),
  }) {
    if (requestLoading != null) {
      return requestLoading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IncrementMessage value) increment,
    required TResult Function(DecrementMessage value) decrement,
    required TResult Function(RequestLoadingMessage value) requestLoading,
    required TResult Function(LoadSuccessfulMessage value) loadSuccessful,
    required TResult Function(LoadFailedMessage value) loadFailed,
  }) {
    return requestLoading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IncrementMessage value)? increment,
    TResult? Function(DecrementMessage value)? decrement,
    TResult? Function(RequestLoadingMessage value)? requestLoading,
    TResult? Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult? Function(LoadFailedMessage value)? loadFailed,
  }) {
    return requestLoading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IncrementMessage value)? increment,
    TResult Function(DecrementMessage value)? decrement,
    TResult Function(RequestLoadingMessage value)? requestLoading,
    TResult Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult Function(LoadFailedMessage value)? loadFailed,
    required TResult orElse(),
  }) {
    if (requestLoading != null) {
      return requestLoading(this);
    }
    return orElse();
  }
}

abstract class RequestLoadingMessage implements CounterMessage {
  const factory RequestLoadingMessage() = _$RequestLoadingMessageImpl;
}

/// @nodoc
abstract class _$$LoadSuccessfulMessageImplCopyWith<$Res> {
  factory _$$LoadSuccessfulMessageImplCopyWith(
    _$LoadSuccessfulMessageImpl value,
    $Res Function(_$LoadSuccessfulMessageImpl) then,
  ) = __$$LoadSuccessfulMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int value});
}

/// @nodoc
class __$$LoadSuccessfulMessageImplCopyWithImpl<$Res>
    extends _$CounterMessageCopyWithImpl<$Res, _$LoadSuccessfulMessageImpl>
    implements _$$LoadSuccessfulMessageImplCopyWith<$Res> {
  __$$LoadSuccessfulMessageImplCopyWithImpl(
    _$LoadSuccessfulMessageImpl _value,
    $Res Function(_$LoadSuccessfulMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? value = null}) {
    return _then(
      _$LoadSuccessfulMessageImpl(
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$LoadSuccessfulMessageImpl implements LoadSuccessfulMessage {
  const _$LoadSuccessfulMessageImpl({required this.value});

  @override
  final int value;

  @override
  String toString() {
    return 'CounterMessage.loadSuccessful(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadSuccessfulMessageImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadSuccessfulMessageImplCopyWith<_$LoadSuccessfulMessageImpl>
  get copyWith =>
      __$$LoadSuccessfulMessageImplCopyWithImpl<_$LoadSuccessfulMessageImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() increment,
    required TResult Function() decrement,
    required TResult Function() requestLoading,
    required TResult Function(int value) loadSuccessful,
    required TResult Function() loadFailed,
  }) {
    return loadSuccessful(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? increment,
    TResult? Function()? decrement,
    TResult? Function()? requestLoading,
    TResult? Function(int value)? loadSuccessful,
    TResult? Function()? loadFailed,
  }) {
    return loadSuccessful?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? increment,
    TResult Function()? decrement,
    TResult Function()? requestLoading,
    TResult Function(int value)? loadSuccessful,
    TResult Function()? loadFailed,
    required TResult orElse(),
  }) {
    if (loadSuccessful != null) {
      return loadSuccessful(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IncrementMessage value) increment,
    required TResult Function(DecrementMessage value) decrement,
    required TResult Function(RequestLoadingMessage value) requestLoading,
    required TResult Function(LoadSuccessfulMessage value) loadSuccessful,
    required TResult Function(LoadFailedMessage value) loadFailed,
  }) {
    return loadSuccessful(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IncrementMessage value)? increment,
    TResult? Function(DecrementMessage value)? decrement,
    TResult? Function(RequestLoadingMessage value)? requestLoading,
    TResult? Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult? Function(LoadFailedMessage value)? loadFailed,
  }) {
    return loadSuccessful?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IncrementMessage value)? increment,
    TResult Function(DecrementMessage value)? decrement,
    TResult Function(RequestLoadingMessage value)? requestLoading,
    TResult Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult Function(LoadFailedMessage value)? loadFailed,
    required TResult orElse(),
  }) {
    if (loadSuccessful != null) {
      return loadSuccessful(this);
    }
    return orElse();
  }
}

abstract class LoadSuccessfulMessage implements CounterMessage {
  const factory LoadSuccessfulMessage({required final int value}) =
      _$LoadSuccessfulMessageImpl;

  int get value;

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadSuccessfulMessageImplCopyWith<_$LoadSuccessfulMessageImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadFailedMessageImplCopyWith<$Res> {
  factory _$$LoadFailedMessageImplCopyWith(
    _$LoadFailedMessageImpl value,
    $Res Function(_$LoadFailedMessageImpl) then,
  ) = __$$LoadFailedMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadFailedMessageImplCopyWithImpl<$Res>
    extends _$CounterMessageCopyWithImpl<$Res, _$LoadFailedMessageImpl>
    implements _$$LoadFailedMessageImplCopyWith<$Res> {
  __$$LoadFailedMessageImplCopyWithImpl(
    _$LoadFailedMessageImpl _value,
    $Res Function(_$LoadFailedMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CounterMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadFailedMessageImpl implements LoadFailedMessage {
  const _$LoadFailedMessageImpl();

  @override
  String toString() {
    return 'CounterMessage.loadFailed()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadFailedMessageImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() increment,
    required TResult Function() decrement,
    required TResult Function() requestLoading,
    required TResult Function(int value) loadSuccessful,
    required TResult Function() loadFailed,
  }) {
    return loadFailed();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? increment,
    TResult? Function()? decrement,
    TResult? Function()? requestLoading,
    TResult? Function(int value)? loadSuccessful,
    TResult? Function()? loadFailed,
  }) {
    return loadFailed?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? increment,
    TResult Function()? decrement,
    TResult Function()? requestLoading,
    TResult Function(int value)? loadSuccessful,
    TResult Function()? loadFailed,
    required TResult orElse(),
  }) {
    if (loadFailed != null) {
      return loadFailed();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IncrementMessage value) increment,
    required TResult Function(DecrementMessage value) decrement,
    required TResult Function(RequestLoadingMessage value) requestLoading,
    required TResult Function(LoadSuccessfulMessage value) loadSuccessful,
    required TResult Function(LoadFailedMessage value) loadFailed,
  }) {
    return loadFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IncrementMessage value)? increment,
    TResult? Function(DecrementMessage value)? decrement,
    TResult? Function(RequestLoadingMessage value)? requestLoading,
    TResult? Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult? Function(LoadFailedMessage value)? loadFailed,
  }) {
    return loadFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IncrementMessage value)? increment,
    TResult Function(DecrementMessage value)? decrement,
    TResult Function(RequestLoadingMessage value)? requestLoading,
    TResult Function(LoadSuccessfulMessage value)? loadSuccessful,
    TResult Function(LoadFailedMessage value)? loadFailed,
    required TResult orElse(),
  }) {
    if (loadFailed != null) {
      return loadFailed(this);
    }
    return orElse();
  }
}

abstract class LoadFailedMessage implements CounterMessage {
  const factory LoadFailedMessage() = _$LoadFailedMessageImpl;
}
