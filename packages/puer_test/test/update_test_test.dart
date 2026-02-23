import 'package:puer/puer.dart';
import 'package:puer_test/puer_test.dart';
import 'package:test/test.dart';

Next<int, String> update(int state, String message) {
  if (message == 'increment') {
    return next(state: state + 1);
  } else if (message == 'decrement') {
    return next(state: state - 1);
  } else if (message == 'with_effect') {
    return next(effects: ['effect']);
  } else if (message == 'both') {
    return next(state: state + 1, effects: ['effect']);
  } else {
    throw Exception('Unknown message: $message');
  }
}

void main() {
  group('UpdateTest', () {
    test(
        'should test the behavior of an Update function with state and without effects',
        () {
      update.test(
        state: 0,
        message: 'increment',
        expectedState: 1,
      );
    });

    test(
        'should test the behavior of an Update function without state and with effects',
        () {
      update.test(
        state: 0,
        message: 'with_effect',
        expectedEffects: ['effect'],
      );
    });

    test(
        'should test the behavior of an Update function with both state and effects',
        () {
      update.test(
        state: 0,
        message: 'both',
        expectedState: 1,
        expectedEffects: ['effect'],
      );
    });
  });
}
