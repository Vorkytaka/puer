import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puer/puer.dart';
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

  testWidgets('FeatureBuilder initializes with correct state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureBuilder<MockFeature, MockState>(
            builder: (context, state) => Text('State: $state'),
          ),
        ),
      ),
    );

    expect(find.text('State: 0'), findsOneWidget);
  });

  testWidgets('FeatureBuilder builds only once on initial mount',
      (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureBuilder<MockFeature, MockState>(
            builder: (context, state) {
              buildCount++;
              return Text('State: $state');
            },
          ),
        ),
      ),
    );

    // Should build exactly once on mount
    expect(buildCount, 1);
    expect(find.text('State: 0'), findsOneWidget);

    // Pump again to ensure no additional builds
    await tester.pump();
    expect(buildCount, 1);
  });

  testWidgets('FeatureBuilder rebuilds when state changes', (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureBuilder<MockFeature, MockState>(
            builder: (context, state) {
              buildCount++;
              return Text('State: $state');
            },
          ),
        ),
      ),
    );

    expect(buildCount, 1);
    expect(find.text('State: 0'), findsOneWidget);

    // Trigger state change
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(buildCount, 2);
    expect(find.text('State: 1'), findsOneWidget);

    // Trigger another state change
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(buildCount, 3);
    expect(find.text('State: 2'), findsOneWidget);
  });

  testWidgets('FeatureBuilder does not rebuild when state is unchanged',
      (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureBuilder<MockFeature, MockState>(
            builder: (context, state) {
              buildCount++;
              return Text('State: $state');
            },
          ),
        ),
      ),
    );

    expect(buildCount, 1);
    expect(find.text('State: 0'), findsOneWidget);

    // Trigger state change that returns the same state
    mockFeature.accept('same');
    await tester.pumpAndSettle();

    // Should not rebuild because state didn't change
    expect(buildCount, 1);
    expect(find.text('State: 0'), findsOneWidget);
  });

  testWidgets('FeatureBuilder respects buildWhen condition', (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureBuilder<MockFeature, MockState>(
            buildWhen: (previous, current) => current.isEven,
            builder: (context, state) {
              buildCount++;
              return Text('State: $state');
            },
          ),
        ),
      ),
    );

    expect(buildCount, 1);
    expect(find.text('State: 0'), findsOneWidget);

    // Change to 1 (odd) - should not rebuild
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(buildCount, 1);
    expect(find.text('State: 0'), findsOneWidget);

    // Change to 2 (even) - should rebuild
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(buildCount, 2);
    expect(find.text('State: 2'), findsOneWidget);

    // Change to 3 (odd) - should not rebuild
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(buildCount, 2);
    expect(find.text('State: 2'), findsOneWidget);
  });

  testWidgets('FeatureBuilder handles multiple rapid state changes',
      (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureBuilder<MockFeature, MockState>(
            builder: (context, state) {
              buildCount++;
              return Text('State: $state');
            },
          ),
        ),
      ),
    );

    expect(buildCount, 1);

    // Trigger multiple state changes one by one
    mockFeature.accept('inc');
    await tester.pump();

    mockFeature.accept('inc');
    await tester.pump();

    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    // Should build once for each state change plus initial
    expect(buildCount, 4);
    expect(find.text('State: 3'), findsOneWidget);
  });

  testWidgets(
      'FeatureBuilder does not cause layout errors during initial build',
      (tester) async {
    // This test specifically checks for the RenderErrorBox issue
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeatureProvider.value(
            value: mockFeature,
            child: FeatureBuilder<MockFeature, MockState>(
              builder: (context, state) => Center(
                child: Text('State: $state'),
              ),
            ),
          ),
        ),
      ),
    );

    // Should not produce any errors
    expect(errors, isEmpty);
    expect(find.text('State: 0'), findsOneWidget);
  });

  testWidgets('FeatureBuilder works with complex widget tree', (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: FeatureProvider.value(
            value: mockFeature,
            child: Column(
              children: [
                const Text('Header'),
                FeatureBuilder<MockFeature, MockState>(
                  builder: (context, state) {
                    buildCount++;
                    return Text('State: $state');
                  },
                ),
                const Text('Footer'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(buildCount, 1);
    expect(find.text('State: 0'), findsOneWidget);
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);

    // Trigger state change
    mockFeature.accept('inc');
    await tester.pumpAndSettle();

    expect(buildCount, 2);
    expect(find.text('State: 1'), findsOneWidget);
  });
}
