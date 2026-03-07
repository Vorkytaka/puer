import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puer_flutter/puer_flutter.dart';

typedef MockState = (int, String);

typedef MockFeature = Feature<MockState, String, void>;

void main() {
  late MockFeature mockFeature;

  setUp(() {
    mockFeature = MockFeature(
      initialState: (10, 'test'),
      update: (state, message) {
        if (message == 'inc') {
          return next(state: (state.$1 + 1, state.$2));
        } else if (message == 'str') {
          return next(state: (state.$1, 'new'));
        }
        return next();
      },
    );
  });

  testWidgets('FeatureSelector initializes with correct value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureSelector<MockFeature, MockState, int>(
            selector: (state) => state.$1,
            builder: (context, value) => Text('$value'),
          ),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('FeatureSelector rebuild when value update', (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureSelector<MockFeature, MockState, int>(
            selector: (state) => state.$1,
            builder: (context, value) {
              buildCount++;
              return Text('$value');
            },
          ),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
    expect(buildCount, 1);

    mockFeature.accept('inc');

    await tester.pumpAndSettle();

    expect(find.text('11'), findsOneWidget);
    expect(buildCount, 2);
  });

  testWidgets(
      'FeatureSelector does not rebuild when part of state does not update',
      (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureProvider.value(
          value: mockFeature,
          child: FeatureSelector<MockFeature, MockState, int>(
            selector: (state) => state.$1,
            builder: (context, value) {
              buildCount++;
              return Text('$value');
            },
          ),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
    expect(buildCount, 1);

    mockFeature.accept('str');

    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);
    expect(buildCount, 1);
  });
}
