import 'dart:async';

import 'package:puer/puer.dart';

/// Converts a stream value of type [T] to a [Message].
///
/// Used by [StreamEffectHandler] to transform stream events into messages
/// that can be emitted to the effect handler system.
typedef ValueToMessage<T, Message> = Message Function(T value);

/// Converts a stream error to an optional [Message].
///
/// Used by [StreamEffectHandler] to handle stream errors gracefully.
/// Return `null` to silently ignore the error, or return a [Message] to
/// emit an error message to the effect handler system.
///
/// Example:
/// ```dart
/// ErrorToMessage<MyMessage> onError = (error, stackTrace) {
///   if (error is NetworkException) {
///     return MyMessage.networkError(error.message);
///   }
///   return null; // Ignore other errors
/// };
/// ```
typedef ErrorToMessage<Message> = Message? Function(
  Object error,
  StackTrace stackTrace,
);

/// Converts stream completion to an optional [Message].
///
/// Used by [StreamEffectHandler] to notify when the stream completes naturally.
/// Return `null` if no notification is needed, or return a [Message] to emit
/// when the stream completes.
///
/// Example:
/// ```dart
/// CompletionToMessage<MyMessage> onDone = () {
///   return MyMessage.streamCompleted();
/// };
/// ```
typedef CompletionToMessage<Message> = Message? Function();

/// A predicate function that determines if an effect matches a condition.
///
/// Used by [StreamEffectHandler] to identify start and stop effects.
typedef EffectPredicate<Effect> = bool Function(Effect effect);

/// Extension on [Stream] that provides a convenient way to create a
/// [StreamEffectHandler].
///
/// Example:
/// ```dart
/// final locationStream = locationService.stream;
/// final handler = locationStream.toEffectHandler<LocationEffect, AppMessage>(
///   mapper: (location) => AppMessage.locationUpdated(location),
///   isStartEffect: (effect) => effect is StartLocationTracking,
///   isEndEffect: (effect) => effect is StopLocationTracking,
/// );
/// ```
extension StreamEffectHandlerExt<T> on Stream<T> {
  /// Creates an [EffectHandler] from this stream.
  ///
  /// The handler will start listening to the stream when an effect matching
  /// [isStartEffect] is received, and stop listening when an effect matching
  /// [isEndEffect] is received.
  ///
  /// Parameters:
  /// - [mapper]: Transforms stream values into messages
  /// - [isStartEffect]: Predicate to identify effects that should start the subscription
  /// - [isEndEffect]: Predicate to identify effects that should stop the subscription
  /// - [onError]: Optional callback to handle stream errors (default: errors are silently ignored)
  /// - [onDone]: Optional callback to handle stream completion (default: no notification)
  EffectHandler<Effect, Message> toEffectHandler<Effect, Message>({
    required ValueToMessage<T, Message> mapper,
    required EffectPredicate<Effect> isStartEffect,
    required EffectPredicate<Effect> isEndEffect,
    ErrorToMessage<Message>? onError,
    CompletionToMessage<Message>? onDone,
  }) =>
      StreamEffectHandler(
        stream: this,
        mapper: mapper,
        isStartEffect: isStartEffect,
        isEndEffect: isEndEffect,
        onError: onError,
        onDone: onDone,
      );
}

/// An [EffectHandler] that manages a subscription to a [Stream] based on effects.
///
/// This handler subscribes to a stream when receiving a "start" effect and
/// unsubscribes when receiving an "end" effect. Stream values are transformed
/// into messages using the [mapper] function and emitted to the effect handler
/// system.
///
/// ## Features
///
/// - **Start/Stop Control**: Uses predicates to determine when to start and stop
///   the stream subscription based on incoming effects.
/// - **Error Handling**: Optional error-to-message converter for graceful error handling.
/// - **Completion Notification**: Optional callback to emit a message when the stream completes.
/// - **Restart Support**: Can be restarted after stopping by receiving another start effect.
/// - **Resource Management**: Implements [Disposable] for proper cleanup.
///
/// ## Lifecycle
///
/// 1. Handler is created but inactive (not subscribed)
/// 2. When [isStartEffect] returns `true`, subscription begins
/// 3. Stream events are mapped to messages and emitted
/// 4. When [isEndEffect] returns `true`, subscription is cancelled
/// 5. Can be restarted by receiving another start effect
/// 6. Call [dispose] to permanently clean up resources
///
/// ## Example Usage
///
/// ```dart
/// // Define your effects
/// sealed class LocationEffect {}
/// class StartLocationTracking extends LocationEffect {}
/// class StopLocationTracking extends LocationEffect {}
///
/// // Define your messages
/// sealed class AppMessage {}
/// class LocationUpdated extends AppMessage {
///   final Location location;
///   LocationUpdated(this.location);
/// }
/// class LocationError extends AppMessage {
///   final String error;
///   LocationError(this.error);
/// }
/// class LocationTrackingCompleted extends AppMessage {}
///
/// // Create the handler
/// final handler = StreamEffectHandler<Location, LocationEffect, AppMessage>(
///   stream: locationService.locationStream,
///   mapper: (location) => LocationUpdated(location),
///   isStartEffect: (effect) => effect is StartLocationTracking,
///   isEndEffect: (effect) => effect is StopLocationTracking,
///   onError: (error, stackTrace) => LocationError(error.toString()),
///   onDone: () => LocationTrackingCompleted(),
/// );
///
/// // Use in your feature
/// final feature = Feature<LocationState, LocationEffect, AppMessage>(
///   effectHandlers: [handler],
///   // ... other configuration
/// );
/// ```
///
/// ## Thread Safety
///
/// This handler is not thread-safe. Effects should be processed sequentially
/// by the effect handler system.
///
/// ## Error Handling
///
/// If [onError] is not provided, stream errors are silently ignored. The
/// subscription remains active after an error. To handle errors:
///
/// ```dart
/// onError: (error, stackTrace) {
///   // Log the error
///   logger.error('Stream error', error, stackTrace);
///   // Convert to message (or return null to ignore)
///   return MyMessage.error(error.toString());
/// }
/// ```
final class StreamEffectHandler<T, Effect, Message>
    implements EffectHandler<Effect, Message>, Disposable {
  final Stream<T> _stream;
  final ValueToMessage<T, Message> _mapper;
  final EffectPredicate<Effect> _isStartEffect;
  final EffectPredicate<Effect> _isEndEffect;
  final ErrorToMessage<Message>? _onError;
  final CompletionToMessage<Message>? _onDone;

  StreamSubscription<T>? _subscription;

  /// Creates a [StreamEffectHandler] that manages a stream subscription.
  ///
  /// Parameters:
  /// - [stream]: The source stream to subscribe to
  /// - [mapper]: Transforms stream values into messages
  /// - [isStartEffect]: Predicate to identify effects that should start the subscription
  /// - [isEndEffect]: Predicate to identify effects that should stop the subscription
  /// - [onError]: Optional callback to convert stream errors to messages
  /// - [onDone]: Optional callback to emit a message when stream completes
  StreamEffectHandler({
    required Stream<T> stream,
    required ValueToMessage<T, Message> mapper,
    required EffectPredicate<Effect> isStartEffect,
    required EffectPredicate<Effect> isEndEffect,
    ErrorToMessage<Message>? onError,
    CompletionToMessage<Message>? onDone,
  })  : _stream = stream,
        _mapper = mapper,
        _isStartEffect = isStartEffect,
        _isEndEffect = isEndEffect,
        _onError = onError,
        _onDone = onDone;

  /// Returns `true` if the handler is currently subscribed to the stream.
  ///
  /// A handler is active after receiving a start effect and becomes inactive
  /// after receiving an end effect or when the stream completes.
  bool get isActive => _subscription != null;

  @override
  Future<void> call(
    Effect effect,
    MsgEmitter<Message> emit,
  ) async {
    if (_isStartEffect(effect)) {
      // If already active, restart by disposing first
      if (_subscription != null) {
        await dispose();
      }

      // Start new subscription
      _subscription = _stream.listen(
        (value) {
          final message = _mapper(value);
          emit(message);
        },
        onError: (Object error, StackTrace stackTrace) {
          final message = _onError?.call(error, stackTrace);
          if (message != null) {
            emit(message);
          }
          // If _onError is null or returns null, error is silently ignored
        },
        onDone: () {
          final message = _onDone?.call();
          if (message != null) {
            emit(message);
          }
          // Clean up subscription reference
          _subscription = null;
        },
      );
    } else if (_isEndEffect(effect)) {
      // Stop subscription if active
      if (_subscription != null) {
        await dispose();
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
