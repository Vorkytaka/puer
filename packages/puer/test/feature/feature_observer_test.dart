import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:puer/feature.dart';
import 'package:test/test.dart';

class MockFeatureObserver<S, Ev, Ef> extends Mock
    implements FeatureObserver<S, Ev, Ef> {}

class MockFeature<S, Ev, Ef> extends Mock implements Feature<S, Ev, Ef> {}

void main() {
  group('FeatureObserverWrapper with FeatureObserver', () {
    late MockFeatureObserver<int, String, String> observer;
    late MockFeature<int, String, String> feature;
    late Feature<int, String, String> wrapper;

    setUp(() {
      observer = MockFeatureObserver<int, String, String>();
      feature = MockFeature<int, String, String>();
      wrapper = feature.observeWith(observer);
    });

    test('onInit is called during init', () async {
      when(() => feature.stateStream).thenAnswer((_) => const Stream.empty());
      when(() => feature.effects).thenAnswer((_) => const Stream.empty());

      await wrapper.init();

      verify(() => observer.onInit()).called(1);
    });

    test('onDispose is called during dispose', () async {
      when(() => feature.dispose()).thenAnswer((_) => Future.value());

      await wrapper.dispose();

      verify(() => observer.onDispose()).called(1);
    });

    test('onEvent is called when an event is accepted', () {
      const event = 'testEvent';
      wrapper.accept(event);

      verify(() => observer.onMsg(event)).called(1);
    });

    test('onState is called when state changes', () async {
      final stateController = StreamController<int>();
      when(() => feature.stateStream).thenAnswer((_) => stateController.stream);
      when(() => feature.effects).thenAnswer((_) => const Stream.empty());

      await wrapper.init();
      stateController.add(42);

      await Future.delayed(Duration.zero);
      verify(() => observer.onState(42)).called(1);

      await stateController.close();
    });

    test('onEffect is called when effects emit', () async {
      final effectController = StreamController<String>();
      when(() => feature.effects).thenAnswer((_) => effectController.stream);
      when(() => feature.stateStream).thenAnswer((_) => const Stream.empty());

      await wrapper.init();
      effectController.add('effect');

      await Future.delayed(Duration.zero);
      verify(() => observer.onEffect('effect')).called(1);

      await effectController.close();
    });
  });

  group('FeatureObserverWrapper with functions', () {
    late MockFeatureObserver<int, String, String> observer;
    late MockFeature<int, String, String> feature;
    late Feature<int, String, String> wrapper;

    setUp(() {
      observer = MockFeatureObserver<int, String, String>();
      feature = MockFeature<int, String, String>();
      wrapper = feature.observe(
        onInit: () => observer.onInit(),
        onDispose: () => observer.onDispose(),
        onState: (state) => observer.onState(state),
        onMsg: (msg) => observer.onMsg(msg),
        onEffect: (effect) => observer.onEffect(effect),
      );
    });

    test('onInit is called during init', () async {
      when(() => feature.stateStream).thenAnswer((_) => const Stream.empty());
      when(() => feature.effects).thenAnswer((_) => const Stream.empty());

      await wrapper.init();

      verify(() => observer.onInit()).called(1);
    });

    test('onDispose is called during dispose', () async {
      when(() => feature.dispose()).thenAnswer((_) => Future.value());

      await wrapper.dispose();

      verify(() => observer.onDispose()).called(1);
    });

    test('onEvent is called when an event is accepted', () {
      const event = 'testEvent';
      wrapper.accept(event);

      verify(() => observer.onMsg(event)).called(1);
    });

    test('onState is called when state changes', () async {
      final stateController = StreamController<int>();
      when(() => feature.stateStream).thenAnswer((_) => stateController.stream);
      when(() => feature.effects).thenAnswer((_) => const Stream.empty());

      await wrapper.init();
      stateController.add(42);

      await Future.delayed(Duration.zero);
      verify(() => observer.onState(42)).called(1);

      await stateController.close();
    });

    test('onEffect is called when effects emit', () async {
      final effectController = StreamController<String>();
      when(() => feature.effects).thenAnswer((_) => effectController.stream);
      when(() => feature.stateStream).thenAnswer((_) => const Stream.empty());

      await wrapper.init();
      effectController.add('effect');

      await Future.delayed(Duration.zero);
      verify(() => observer.onEffect('effect')).called(1);

      await effectController.close();
    });
  });
}
