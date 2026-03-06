// ignore_for_file: avoid_print

import 'package:puer_time_travel/puer_time_travel.dart';

/// Counter state
final class CounterState {
  const CounterState(this.count);

  final int count;

  static const initial = CounterState(0);

  @override
  String toString() => 'CounterState(count: $count)';
}

/// Counter messages
sealed class CounterMessage {
  const CounterMessage();
}

final class Increment extends CounterMessage {
  const Increment();
}

final class Decrement extends CounterMessage {
  const Decrement();
}

final class Reset extends CounterMessage {
  const Reset();
}

/// Counter effects (none in this simple example)
sealed class CounterEffect {
  const CounterEffect();
}

/// Update function - pure business logic
(CounterState?, List<CounterEffect>) counterUpdate(
  CounterState state,
  CounterMessage message,
) {
  return switch (message) {
    Increment() => (CounterState(state.count + 1), []),
    Decrement() => (CounterState(state.count - 1), []),
    Reset() => (CounterState.initial, []),
  };
}

void main() async {
  print('=== Puer Time Travel Example ===\n');

  // Create a TimeTravelFeature instead of a regular Feature
  final feature =
      TimeTravelFeature<CounterState, CounterMessage, CounterEffect>(
    name: 'CounterFeature',
    initialState: CounterState.initial,
    update: counterUpdate,
  );

  // Initialize the feature
  await feature.init();

  // Get the controller
  final controller = TimeTravelController();

  // Simulate user interactions
  print('Performing operations:');
  print('  Initial state: ${feature.state}');

  feature.accept(const Increment());
  await Future<void>.delayed(Duration.zero); // Let state propagate
  print('  After Increment: ${feature.state}');

  feature.accept(const Increment());
  await Future<void>.delayed(Duration.zero);
  print('  After Increment: ${feature.state}');

  feature.accept(const Increment());
  await Future<void>.delayed(Duration.zero);
  print('  After Increment: ${feature.state}');

  feature.accept(const Decrement());
  await Future<void>.delayed(Duration.zero);
  print('  After Decrement: ${feature.state}');

  // Demonstrate time travel
  print('\n--- Time Travel Demo ---');
  print('Current state: ${feature.state}');
  print('Is time traveling: ${controller.isTimeTraveling}\n');

  // Go back in time
  print('Going back one step...');
  controller.goBack();
  await Future<void>.delayed(Duration.zero);
  print('State after goBack(): ${feature.state}');
  print('Is time traveling: ${controller.isTimeTraveling}\n');

  // Go back more
  print('Going back to start...');
  controller.goToStart();
  await Future<void>.delayed(Duration.zero);
  print('State at start: ${feature.state}');
  print('Is time traveling: ${controller.isTimeTraveling}\n');

  // Go forward
  print('Going forward one step...');
  controller.goForward();
  await Future<void>.delayed(Duration.zero);
  print('State after goForward(): ${feature.state}\n');

  // Jump to end
  print('Jumping to end...');
  controller.goToEnd();
  await Future<void>.delayed(Duration.zero);
  print('State at end: ${feature.state}');
  print('Is time traveling: ${controller.isTimeTraveling}\n');

  // End time travel and continue with new messages
  print('Ending time travel...');
  controller.endTimeTravel();
  await Future<void>.delayed(Duration.zero);
  print('Is time traveling: ${controller.isTimeTraveling}\n');

  print('Adding new operations after time travel:');
  feature.accept(const Increment());
  await Future<void>.delayed(Duration.zero);
  print('  After Increment: ${feature.state}');

  feature.accept(const Reset());
  await Future<void>.delayed(Duration.zero);
  print('  After Reset: ${feature.state}');

  // Timeline info
  final timeline = controller.state.timeline;
  print('\nTimeline has ${timeline.length} events');
  print(
    'Timeline: ${timeline.map((e) => e.message.runtimeType.toString()).join(' -> ')}',
  );

  // Clean up
  await feature.dispose();
  await controller.dispose();

  print('\n=== Example Complete ===');
  print(
    'In Flutter DevTools, you would see a visual timeline and navigation controls.',
  );
}
