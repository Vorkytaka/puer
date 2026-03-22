import 'dart:async';

import 'package:puer/puer.dart';
import 'package:test/test.dart';

void main() {
  group('ReadOnlyFeatureWrapper', () {
    late Feature<int, String, String> feature;
    late ReadOnlyFeature<int, String, String> readOnlyFeature;

    setUp(() async {
      feature = Feature<int, String, String>(
        initialState: 0,
        update: (state, message) {
          if (message == 'increment') {
            return (state + 1, []);
          } else if (message == 'with_effect') {
            return (state + 1, ['effect1']);
          } else if (message == 'only_effect') {
            return (null, ['effect2']);
          }
          return (null, []);
        },
        effectHandlers: [],
        initialEffects: ['initial_effect'],
        disposableEffects: ['dispose_effect'],
      );

      await feature.init();
      readOnlyFeature = ReadOnlyFeatureWrapper(feature: feature);
    });

    tearDown(() async {
      await feature.dispose();
    });

    group('delegates read operations correctly', () {
      test('provides access to current state', () {
        expect(readOnlyFeature.state, equals(0));

        feature.add('increment');

        expect(readOnlyFeature.state, equals(1));
      });

      test('provides access to stateStream', () async {
        final states = <int>[];
        readOnlyFeature.stateStream.listen(states.add);

        feature.add('increment');
        await Future<void>.delayed(Duration.zero);

        expect(states, equals([0, 1]));
      });

      test('provides access to effects stream', () async {
        final effects = <String>[];
        readOnlyFeature.effects.listen(effects.add);

        feature.add('with_effect');
        await Future<void>.delayed(Duration.zero);

        expect(effects, equals(['effect1']));
      });

      test('provides access to transitions stream', () async {
        final transitions = <Transition<int, String, String>>[];
        readOnlyFeature.transitions.listen(transitions.add);

        feature.add('increment');
        await Future<void>.delayed(Duration.zero);

        expect(transitions, hasLength(1));
        expect(transitions.first.stateBefore, equals(0));
        expect(transitions.first.message, equals('increment'));
        expect(transitions.first.stateAfter, equals(1));
        expect(transitions.first.effects, isEmpty);
      });

      test('provides access to initialEffects', () {
        expect(readOnlyFeature.initialEffects, equals(['initial_effect']));
      });

      test('provides access to disposableEffects', () {
        expect(readOnlyFeature.disposableEffects, equals(['dispose_effect']));
      });
    });

    group('wrapper behavior', () {
      test('can be created with const constructor', () {
        const wrapper = ReadOnlyFeatureWrapper<int, String, String>(
          feature: _TestReadOnlyFeature(),
        );

        expect(wrapper, isNotNull);
      });

      test('is a final class (cannot be extended)', () {
        // This is a compile-time check, but we can verify the type
        expect(readOnlyFeature, isA<ReadOnlyFeatureWrapper>());
        expect(readOnlyFeature, isA<ReadOnlyFeature>());
      });

      test('does not expose Feature methods', () {
        // Verify that readOnlyFeature does not have Feature interface methods
        expect(readOnlyFeature is Feature, isFalse);
        expect(readOnlyFeature is Disposable, isFalse);

        // This is a compile-time check - the following would not compile:
        // readOnlyFeature.add('message');
        // readOnlyFeature.init();
        // readOnlyFeature.dispose();
      });
    });

    group('multiple wrappers', () {
      test('multiple wrappers of same feature work independently', () async {
        final wrapper1 = ReadOnlyFeatureWrapper(feature: feature);
        final wrapper2 = ReadOnlyFeatureWrapper(feature: feature);

        final states1 = <int>[];
        final states2 = <int>[];

        wrapper1.stateStream.listen(states1.add);
        wrapper2.stateStream.listen(states2.add);

        feature.add('increment');
        await Future<void>.delayed(Duration.zero);

        // Both wrappers should see the same state changes
        expect(states1, equals([0, 1]));
        expect(states2, equals([0, 1]));
      });

      test('nested wrapping works correctly', () {
        final wrapper1 = ReadOnlyFeatureWrapper(feature: feature);
        final wrapper2 = ReadOnlyFeatureWrapper(feature: wrapper1);

        expect(wrapper2.state, equals(0));

        feature.add('increment');

        expect(wrapper2.state, equals(1));
      });
    });
  });

  group('ReadOnlyFeatureWrapperExt', () {
    late Feature<int, String, String> feature;

    setUp(() async {
      feature = Feature<int, String, String>(
        initialState: 42,
        update: (state, message) {
          if (message == 'double') {
            return (state * 2, []);
          }
          return (null, []);
        },
        effectHandlers: [],
      );

      await feature.init();
    });

    tearDown(() async {
      await feature.dispose();
    });

    test('asReadOnly creates a ReadOnlyFeatureWrapper', () {
      final readOnly = feature.asReadOnly;

      expect(readOnly, isA<ReadOnlyFeatureWrapper>());
      expect(readOnly, isA<ReadOnlyFeature>());
      expect(readOnly is Feature, isFalse);
    });

    test('asReadOnly provides access to state', () {
      final readOnly = feature.asReadOnly;

      expect(readOnly.state, equals(42));

      feature.add('double');

      expect(readOnly.state, equals(84));
    });

    test('asReadOnly provides access to streams', () async {
      final readOnly = feature.asReadOnly;

      final states = <int>[];
      readOnly.stateStream.listen(states.add);

      feature.add('double');
      await Future<void>.delayed(Duration.zero);

      expect(states, equals([42, 84]));
    });

    test('calling asReadOnly multiple times creates separate wrappers', () {
      final readOnly1 = feature.asReadOnly;
      final readOnly2 = feature.asReadOnly;

      // They should be different instances
      expect(identical(readOnly1, readOnly2), isFalse);

      // But they should wrap the same feature and show the same state
      expect(readOnly1.state, equals(readOnly2.state));
    });

    test('asReadOnly can be chained', () {
      final readOnly1 = feature.asReadOnly;
      final readOnly2 = readOnly1.asReadOnly;

      expect(readOnly2.state, equals(42));

      feature.add('double');

      expect(readOnly2.state, equals(84));
    });
  });

  group('ReadOnlyFeature interface', () {
    test('Feature implements ReadOnlyFeature', () async {
      final feature = Feature<int, String, String>(
        initialState: 0,
        update: (state, message) => (null, []),
      );

      await feature.init();

      expect(feature, isA<ReadOnlyFeature>());

      await feature.dispose();
    });

    test('can pass Feature where ReadOnlyFeature is expected', () {
      void acceptReadOnly(ReadOnlyFeature<int, String, String> readOnly) {
        expect(readOnly.state, equals(0));
      }

      final feature = Feature<int, String, String>(
        initialState: 0,
        update: (state, message) => (null, []),
      );

      // This should compile and work
      acceptReadOnly(feature);
    });
  });
}

// Test implementation for const constructor test
class _TestReadOnlyFeature implements ReadOnlyFeature<int, String, String> {
  const _TestReadOnlyFeature();

  @override
  Iterable<String> get disposableEffects => const [];

  @override
  Stream<String> get effects => const Stream.empty();

  @override
  Iterable<String> get initialEffects => const [];

  @override
  int get state => 0;

  @override
  Stream<int> get stateStream => const Stream.empty();

  @override
  Stream<Transition<int, String, String>> get transitions =>
      const Stream.empty();
}
