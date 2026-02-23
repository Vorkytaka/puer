import 'dart:async';

import 'package:meta/meta.dart';

import '../feature/core/feature.dart';

/// An [EffectHandler] implementation that adds a debounce mechanism to effect handling.
///
/// Debouncing ensures that effect handling is postponed until a specified [duration]
/// has elapsed since the last effect invocation. If new effects are scheduled during
/// the delay, the previous effect is canceled, and only the most recent effect is processed.
///
/// This is particularly useful in scenarios where effects are triggered in rapid succession,
/// such as handling user input or network requests, and you want to limit the frequency
/// of effect processing.
///
/// ### Example:
/// ```dart
/// final debounceHandler = DebounceEffectHandler(
///   duration: const Duration(milliseconds: 300),
///   handler: myEffectHandler,
/// );
/// ```
@experimental
final class DebounceEffectHandler<Effect, Msg>
    implements EffectHandler<Effect, Msg>, Disposable {
  /// The duration to wait before handling the effect.
  ///
  /// This defines the debounce interval. Any effect scheduled within this
  /// interval cancels the previous one, ensuring only the latest effect is processed.
  final Duration duration;

  /// The underlying effect handler that processes the effects after the debounce interval.
  ///
  /// This handler is invoked with the debounced effect once the delay has elapsed.
  final EffectHandler<Effect, Msg> _handler;

  /// The timer used to manage the debounce delay.
  Timer? _timer;

  /// Creates a new [DebounceEffectHandler].
  ///
  /// - [duration]: The debounce interval. Effects scheduled within this time frame
  ///   cancel previously scheduled effects.
  /// - [handler]: The actual effect handler to invoke after the debounce delay.
  DebounceEffectHandler({
    required this.duration,
    required EffectHandler<Effect, Msg> handler,
  }) : _handler = handler;

  /// Handles an effect with debounce logic.
  ///
  /// If an effect is already scheduled for handling, it will be canceled, and the
  /// new effect will replace it. After the debounce [duration], the latest effect
  /// is processed using the wrapped [_handler].
  ///
  /// - [effect]: The effect to be processed after the debounce delay.
  /// - [emit]: A function to emit messages resulting from the effect.
  @override
  FutureOr<void> call(
    Effect effect,
    MsgEmitter<Msg> emit,
  ) {
    _cancelTimer();
    _timer = Timer(duration, () => _handler(effect, emit));
  }

  /// Cancels any currently scheduled effect handling.
  ///
  /// This is useful for cleaning up resources or if no further effect handling
  /// is required.
  @override
  Future<void> dispose() async {
    _cancelTimer();
  }

  /// Cancels the current timer and clears its reference.
  ///
  /// Called internally to ensure only one effect is scheduled at a time.
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
