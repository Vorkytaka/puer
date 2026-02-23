// ignore_for_file: unnecessary_lambdas, implicit_call_tearoffs

import 'package:mocktail/mocktail.dart';
import 'package:puer/feature.dart';
import 'package:test/test.dart';

sealed class Effect {}

class LeftEffect implements Effect {}

class RightEffect implements Effect {}

class MockFeature extends Mock implements Feature<dynamic, dynamic, Effect> {}

class MockEffectHandler extends Mock
    implements EffectHandler<Effect, dynamic> {}

class MockDisposableEffectHandler extends Mock
    implements EffectHandler<Effect, dynamic>, Disposable {}

class MockLeftEffectHandler extends Mock
    implements EffectHandler<LeftEffect, dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(LeftEffect());
    registerFallbackValue(RightEffect());
  });

  group('EffectHandlerWrapper', () {
    test('Wrapper handle correct effects', () async {
      final mockHandler = MockLeftEffectHandler();
      final mockFeature = MockFeature();
      final leftEffect = LeftEffect();

      when(() => mockFeature.dispose()).thenAnswer((_) => Future.value());
      when(() => mockFeature.effects)
          .thenAnswer((_) => Stream.value(leftEffect));
      when(() => mockFeature.initialEffects).thenReturn(const []);

      final wrapper = mockFeature.wrapEffects<LeftEffect>(mockHandler);
      wrapper.init();
      await Future.value();

      verify(() => mockHandler.call(leftEffect, any())).called(1);
    });

    test('Wrapper ignore other effects', () async {
      final mockHandler = MockLeftEffectHandler();
      final mockFeature = MockFeature();
      final rightEffect = RightEffect();

      when(() => mockFeature.dispose()).thenAnswer((_) => Future.value());
      when(() => mockFeature.effects)
          .thenAnswer((_) => Stream.value(rightEffect));
      when(() => mockFeature.initialEffects).thenReturn(const []);

      final wrapper = mockFeature.wrapEffects<LeftEffect>(mockHandler);
      wrapper.init();
      await Future.value();

      verifyNever(() => mockHandler.call(any(), any()));
    });

    test('Two wrapper works fine', () async {
      final mockFeature = MockFeature();
      final mockHandler1 = MockLeftEffectHandler();
      final mockHandler2 = MockLeftEffectHandler();
      final leftEffect = LeftEffect();

      when(() => mockFeature.dispose()).thenAnswer((_) => Future.value());
      when(() => mockFeature.effects)
          .thenAnswer((_) => Stream.value(leftEffect));
      when(() => mockFeature.initialEffects).thenReturn(const []);

      final wrapper = mockFeature
          .wrapEffects<LeftEffect>(mockHandler1)
          .wrapEffects<LeftEffect>(mockHandler2);
      wrapper.init();
      await Future.value();

      verify(() => mockHandler1.call(leftEffect, any())).called(1);
      verify(() => mockHandler2.call(leftEffect, any())).called(1);
    });

    test('Disposable Effect Handler disposed with the feature', () async {
      final mockHandler = MockDisposableEffectHandler();
      final mockFeature = MockFeature();

      when(() => mockFeature.disposableEffects).thenReturn(const []);
      when(() => mockFeature.dispose()).thenAnswer((_) => Future.value());
      when(() => mockHandler.dispose()).thenAnswer((_) => Future.value());

      final wrapper = mockFeature.wrapEffects(mockHandler);
      await wrapper.dispose();

      verify(() => mockHandler.dispose()).called(1);
    });
  });
}
