import 'package:puer/feature.dart';
import 'package:test/test.dart';

void main() {
  group('Feature transitions', () {
    late Feature<int, String, String> feature;

    setUp(() {
      feature = Feature<int, String, String>(
        initialState: 0,
        update: (state, message) {
          if (message == 'increment') {
            return (state + 1, []);
          } else if (message == 'no_change') {
            return (null, []);
          } else if (message == 'with_effects') {
            return (state + 1, ['effect1', 'effect2']);
          } else if (message == 'only_effects') {
            return (null, ['effect1']);
          } else if (message == 'same_state') {
            return (state, []);
          }
          return (null, []);
        },
        effectHandlers: [],
      );
    });

    tearDown(() async {
      await feature.dispose();
    });

    test('emits transition when state changes', () async {
      final transitions = <Transition<int, String, String>>[];
      feature.transitions.listen(transitions.add);

      feature.accept('increment');

      await Future.delayed(Duration.zero);
      expect(transitions.length, 1);
      expect(transitions[0].stateBefore, 0);
      expect(transitions[0].message, 'increment');
      expect(transitions[0].stateAfter, 1);
      expect(transitions[0].effects, isEmpty);
    });

    test('emits transition when state does not change (null)', () async {
      final transitions = <Transition<int, String, String>>[];
      feature.transitions.listen(transitions.add);

      feature.accept('no_change');

      await Future.delayed(Duration.zero);
      expect(transitions.length, 1);
      expect(transitions[0].stateBefore, 0);
      expect(transitions[0].message, 'no_change');
      expect(transitions[0].stateAfter, null);
      expect(transitions[0].effects, isEmpty);
    });

    test('emits transition when state is same as before', () async {
      final transitions = <Transition<int, String, String>>[];
      feature.transitions.listen(transitions.add);

      feature.accept('same_state');

      await Future.delayed(Duration.zero);
      expect(transitions.length, 1);
      expect(transitions[0].stateBefore, 0);
      expect(transitions[0].message, 'same_state');
      // When update returns the same state, it's treated as "no change"
      // by emitState logic, but transition still has the state value
      expect(transitions[0].stateAfter, 0);
      expect(transitions[0].effects, isEmpty);
    });

    test('emits transition with effects', () async {
      final transitions = <Transition<int, String, String>>[];
      feature.transitions.listen(transitions.add);

      feature.accept('with_effects');

      await Future.delayed(Duration.zero);
      expect(transitions.length, 1);
      expect(transitions[0].stateBefore, 0);
      expect(transitions[0].message, 'with_effects');
      expect(transitions[0].stateAfter, 1);
      expect(transitions[0].effects, ['effect1', 'effect2']);
    });

    test('emits transition with only effects (no state change)', () async {
      final transitions = <Transition<int, String, String>>[];
      feature.transitions.listen(transitions.add);

      feature.accept('only_effects');

      await Future.delayed(Duration.zero);
      expect(transitions.length, 1);
      expect(transitions[0].stateBefore, 0);
      expect(transitions[0].message, 'only_effects');
      expect(transitions[0].stateAfter, null);
      expect(transitions[0].effects, ['effect1']);
    });

    test('emits multiple transitions for multiple messages', () async {
      final transitions = <Transition<int, String, String>>[];
      feature.transitions.listen(transitions.add);

      feature.accept('increment');
      feature.accept('increment');
      feature.accept('no_change');

      await Future.delayed(Duration.zero);
      expect(transitions.length, 3);

      expect(transitions[0].stateBefore, 0);
      expect(transitions[0].stateAfter, 1);

      expect(transitions[1].stateBefore, 1);
      expect(transitions[1].stateAfter, 2);

      expect(transitions[2].stateBefore, 2);
      expect(transitions[2].stateAfter, null);
    });

    test('transitions stream closes when feature is disposed', () async {
      var streamClosed = false;
      feature.transitions.listen(
        (_) {},
        onDone: () => streamClosed = true,
      );

      await feature.dispose();
      await Future.delayed(Duration.zero);

      expect(streamClosed, isTrue);
    });

    test('does not emit transition after dispose', () async {
      await feature.dispose();

      expect(
        () => feature.accept('increment'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
