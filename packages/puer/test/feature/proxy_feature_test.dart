// ignore_for_file: unnecessary_lambdas

import 'package:mocktail/mocktail.dart';
import 'package:puer/feature.dart';
import 'package:test/test.dart';

class MockFeature extends Mock implements Feature {}

final class TestProxyFeature extends ProxyFeature {
  const TestProxyFeature({required super.feature});
}

void main() {
  test('ProxyFeature forwards calls to a nested Feature', () {
    final mockFeature = MockFeature();
    final proxyFeature = TestProxyFeature(feature: mockFeature);

    when(() => mockFeature.dispose()).thenAnswer((_) => Future.value());
    when(() => mockFeature.stateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockFeature.effects).thenAnswer((_) => const Stream.empty());

    proxyFeature.accept(1);
    proxyFeature.state;
    proxyFeature.stateStream;
    proxyFeature.init();
    proxyFeature.dispose();
    proxyFeature.effects;

    verify(() => mockFeature.accept(1)).called(1);
    verify(() => mockFeature.init()).called(1);
    verify(() => mockFeature.dispose()).called(1);
    verify(() => mockFeature.state).called(1);
    verify(() => mockFeature.stateStream).called(1);
    verify(() => mockFeature.effects).called(1);
  });
}
