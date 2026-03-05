import 'dart:async';

import 'package:puer/puer.dart';
import 'package:puer_effect_handlers/puer_effect_handlers.dart';

/// A simple [EffectHandler] implementation for demonstration.
///
/// - Takes an integer effect as input.
/// - Emits a string message as output.
class ExampleEffectHandler implements EffectHandler<int, String> {
  @override
  Future<void> call(int effect, MsgEmitter<String> emit) async {
    // Simple logic: Convert the integer effect to a string message.
    emit('Effect processed: $effect');
  }
}

Future<void> main() async {
  // Create the base handler
  final handler = ExampleEffectHandler();

  // 1. Use the isolate wrapper
  final isolatedHandler = handler.isolated();
  print('--- Isolated Handler ---');
  await isolatedHandler(42, (msg) => print(msg));

  // 2. Use the sequential wrapper
  final sequentialHandler = handler.sequential();
  print('\n--- Sequential Handler ---');
  await Future.wait([
    Future(() => sequentialHandler(1, (msg) => print(msg))),
    Future(() => sequentialHandler(2, (msg) => print(msg))),
    Future(() => sequentialHandler(3, (msg) => print(msg))),
  ]);

  // 3. Use the debounce wrapper
  final debouncedHandler = handler.debounced(const Duration(milliseconds: 300));
  print('\n--- Debounced Handler ---');
  debouncedHandler(10, (msg) => print(msg));
  debouncedHandler(20, (msg) => print(msg)); // This will cancel the first one.
  await Future.delayed(const Duration(milliseconds: 400));

  // 4. Use the adapt wrapper
  final adaptedHandler = handler.adapt<String, int>(
    effectMapper: (String effect) => int.parse(effect),
    messageMapper: (String message) => message.length,
  );
  print('\n--- Adapted Handler ---');
  await adaptedHandler('123456', (msg) => print(msg));
}
