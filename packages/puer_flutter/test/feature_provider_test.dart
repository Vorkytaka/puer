// ignore_for_file: unnecessary_lambdas

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:puer/puer.dart';
import 'package:puer_flutter/puer_flutter.dart';

class MockFeature extends Mock implements Feature {}

void main() {
  group('FeatureProvider Tests', () {
    late MockFeature mockFeature;

    setUp(() {
      mockFeature = MockFeature();

      when(() => mockFeature.stateStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockFeature.dispose()).thenAnswer((_) => Future.value());
    });

    testWidgets('FeatureProvider.create initializes feature on creation',
        (tester) async {
      await tester.pumpWidget(
        FeatureProvider<MockFeature>.create(
          create: (_) => mockFeature,
          child: Builder(
            builder: (context) {
              FeatureProvider.of<MockFeature>(context);
              return Container();
            },
          ),
        ),
      );

      verify(() => mockFeature.init()).called(1);
    });

    testWidgets('FeatureProvider.value does not call init', (tester) async {
      await tester.pumpWidget(
        FeatureProvider.value(
          value: mockFeature,
          child: Builder(
            builder: (context) {
              FeatureProvider.of<MockFeature>(context);
              return Container();
            },
          ),
        ),
      );

      verifyNever(() => mockFeature.init());
    });

    testWidgets(
        'FeatureProvider.create with lazy initialization does not call init until accessed',
        (tester) async {
      await tester.pumpWidget(
        FeatureProvider.create(
          create: (_) => mockFeature,
          lazy: true,
          child: Container(),
        ),
      );

      verifyNever(() => mockFeature.init());

      await tester.pumpWidget(
        FeatureProvider.create(
          create: (_) => mockFeature,
          lazy: true,
          child: Builder(
            builder: (context) {
              FeatureProvider.of<MockFeature>(context);
              return Container();
            },
          ),
        ),
      );

      verify(() => mockFeature.init()).called(1);
    });
  });
}
