import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puer_flutter/puer_flutter.dart';

typedef MockState = int;

typedef MockFeature = Feature<MockState, String, void>;

void main() {
  late MockFeature mockFeature;

  setUp(() {
    mockFeature = MockFeature(
      initialState: 0,
      update: (state, message) {
        if (message == 'inc') {
          return next(state: state + 1);
        } else if (message == 'same') {
          return next(state: state);
        }
        return next();
      },
    );
  });

  testWidgets('FeatureListener does not call listener on initial subscription',
      (tester) async {
    int listenerCallCount = 0;
    final states = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureListener<MockFeature, MockState>(
            listener: (context, state) {
              listenerCallCount++;
              states.add(state);
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );

    // Initial pump should not trigger listener
    await tester.pump();

    expect(listenerCallCount, 0);
    expect(states, isEmpty);
  });

  testWidgets('FeatureListener calls listener on state change', (tester) async {
    int listenerCallCount = 0;
    final states = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureListener<MockFeature, MockState>(
            listener: (context, state) {
              listenerCallCount++;
              states.add(state);
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );

    expect(listenerCallCount, 0);

    // Trigger state change
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(listenerCallCount, 1);
    expect(states, [1]);

    // Trigger another state change
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(listenerCallCount, 2);
    expect(states, [1, 2]);
  });

  testWidgets('FeatureListener does not call listener when state is unchanged',
      (tester) async {
    int listenerCallCount = 0;
    final states = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureListener<MockFeature, MockState>(
            listener: (context, state) {
              listenerCallCount++;
              states.add(state);
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );

    expect(listenerCallCount, 0);

    // Trigger state change that returns the same state
    mockFeature.accept('same');
    await tester.pumpAndSettle();

    // Listener should not be called because state didn't change
    expect(listenerCallCount, 0);
    expect(states, isEmpty);
  });

  testWidgets('FeatureListener respects listenWhen condition', (tester) async {
    int listenerCallCount = 0;
    final states = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureListener<MockFeature, MockState>(
            listenWhen: (previous, current) => current.isEven,
            listener: (context, state) {
              listenerCallCount++;
              states.add(state);
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );

    expect(listenerCallCount, 0);

    // Change to 1 (odd) - should not trigger listener
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(listenerCallCount, 0);
    expect(states, isEmpty);

    // Change to 2 (even) - should trigger listener
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(listenerCallCount, 1);
    expect(states, [2]);

    // Change to 3 (odd) - should not trigger listener
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(listenerCallCount, 1);
    expect(states, [2]);
  });

  testWidgets('FeatureListener handles multiple rapid state changes',
      (tester) async {
    int listenerCallCount = 0;
    final states = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureListener<MockFeature, MockState>(
            listener: (context, state) {
              listenerCallCount++;
              states.add(state);
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );

    // Trigger multiple rapid state changes
    mockFeature.accept('inc');
    mockFeature.accept('inc');
    mockFeature.accept('inc');

    await tester.pumpAndSettle();

    expect(listenerCallCount, 3);
    expect(states, [1, 2, 3]);
  });

  testWidgets('FeatureListener unsubscribes on dispose', (tester) async {
    int listenerCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureListener<MockFeature, MockState>(
            listener: (context, state) {
              listenerCallCount++;
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );

    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(listenerCallCount, 1);

    // Remove the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Text('Empty'),
      ),
    );

    // Trigger state change after disposal
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    // Listener should not be called after disposal
    expect(listenerCallCount, 1);
  });
}
