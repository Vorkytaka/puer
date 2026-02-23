import 'dart:async';

/// A lightweight stream that holds a current value and emits it to new listeners.
///
/// This is a minimal implementation similar to RxDart's `BehaviorSubject`.
/// It maintains a current [value] and provides a [stream] that:
/// - Synchronously emits the current value to new listeners
/// - Subsequently emits all future values added via [add]
///
/// Example:
/// ```dart
/// final state = StateStream.seeded(0);
///
/// state.stream.listen(print); // Immediately prints: 0
/// state.add(1);               // Prints: 1
/// state.add(2);               // Prints: 2
///
/// print(state.value);         // Prints: 2
/// await state.close();
/// ```
final class StateStream<T> {
  T _value;
  final StreamController<T> _controller;

  /// Creates a [StateStream] with an initial [value].
  ///
  /// New listeners to [stream] will immediately receive this value,
  /// or the most recent value added via [add].
  StateStream.seeded(T value)
      : _value = value,
        _controller = StreamController.broadcast(sync: true);

  /// Adds a new [value] to the stream.
  ///
  /// The [value] is stored and emitted to all active listeners.
  /// This also updates the current [value] returned by the getter.
  void add(T value) {
    _value = value;
    _controller.add(value);
  }

  /// The current value.
  ///
  /// This is the value that will be synchronously delivered to new listeners
  /// when they subscribe to [stream].
  T get value => _value;

  /// Whether the underlying broadcast controller has any active listeners.
  ///
  /// Useful for detecting potential memory leaks or verifying cleanup.
  bool get hasListener => _controller.hasListener;

  /// A stream that emits the current value synchronously on listen,
  /// then all subsequent values.
  ///
  /// Each call to this getter creates a new independent subscription.
  /// New listeners will receive:
  /// 1. The current [value] synchronously (before `.listen()` returns)
  /// 2. All future values added via [add]
  Stream<T> get stream => _StateStream<T>(this);

  /// Closes the stream.
  ///
  /// After calling this, no more values can be added, and all active
  /// listeners will receive a done event. The current [value] remains accessible.
  Future<void> close() => _controller.close();
}

/// A custom [Stream] that synchronously delivers the current value
/// of a [StateStream] to new listeners, then forwards all subsequent
/// events from the underlying broadcast controller.
class _StateStream<T> extends Stream<T> {
  final StateStream<T> _subject;

  _StateStream(this._subject);

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = _subject._controller.stream.listen(
      null,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    subscription.onData(onData);

    // Deliver the current value synchronously before returning.
    onData?.call(_subject._value);

    return subscription;
  }
}
