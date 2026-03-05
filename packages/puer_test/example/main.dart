// ignore_for_file: unused_local_variable

import 'package:meta/meta.dart';
import 'package:puer/puer.dart';
import 'package:puer_test/puer_test.dart';
import 'package:test/test.dart';

// Counter domain types
@immutable
final class CounterState {
  const CounterState({required this.count});

  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterState &&
          runtimeType == other.runtimeType &&
          count == other.count;

  @override
  int get hashCode => count.hashCode;
}

sealed class CounterMessage {}

final class Increment extends CounterMessage {}

final class Decrement extends CounterMessage {}

final class Reset extends CounterMessage {}

sealed class CounterEffect {
  const CounterEffect();
}

@immutable
final class SaveCount extends CounterEffect {
  const SaveCount(this.count);

  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveCount &&
          runtimeType == other.runtimeType &&
          count == other.count;

  @override
  int get hashCode => count.hashCode;
}

// Update function
Next<CounterState, CounterEffect> counterUpdate(
  CounterState state,
  CounterMessage message,
) =>
    switch (message) {
      Increment() => next(
          state: CounterState(count: state.count + 1),
          effects: [SaveCount(state.count + 1)],
        ),
      Decrement() => next(
          state: CounterState(count: state.count - 1),
          effects: [SaveCount(state.count - 1)],
        ),
      Reset() => next(
          state: const CounterState(count: 0),
          effects: [const SaveCount(0)],
        ),
    };

void main() {
  group('CounterUpdate', () {
    test('Increment increases count by 1', () {
      counterUpdate.test(
        state: const CounterState(count: 5),
        message: Increment(),
        expectedState: const CounterState(count: 6),
        expectedEffects: [const SaveCount(6)],
      );
    });

    test('Decrement decreases count by 1', () {
      counterUpdate.test(
        state: const CounterState(count: 10),
        message: Decrement(),
        expectedState: const CounterState(count: 9),
        expectedEffects: [const SaveCount(9)],
      );
    });

    test('Reset returns to zero', () {
      counterUpdate.test(
        state: const CounterState(count: 42),
        message: Reset(),
        expectedState: const CounterState(count: 0),
        expectedEffects: [const SaveCount(0)],
      );
    });
  });
}
