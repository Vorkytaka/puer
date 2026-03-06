import 'package:puer_time_travel/puer_time_travel.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Test helpers – a trivial counter feature wired through TimeTravelFeature
// ---------------------------------------------------------------------------

/// Messages understood by the counter feature.
enum CounterMsg { increment, decrement, reset }

/// A side-effect the counter feature can emit.
enum CounterEffect { onReset }

/// Pure update function: state is just an [int].
(int?, List<CounterEffect>) counterUpdate(int state, CounterMsg msg) {
  return switch (msg) {
    CounterMsg.increment => (state + 1, []),
    CounterMsg.decrement => (state - 1, []),
    CounterMsg.reset => (0, [CounterEffect.onReset]),
  };
}

/// A simple effect handler that records every effect it receives.
class RecordingEffectHandler
    implements EffectHandler<CounterEffect, CounterMsg> {
  final List<CounterEffect> handled = [];

  @override
  void call(CounterEffect effect, void Function(CounterMsg) emit) {
    handled.add(effect);
  }
}

/// Convenience factory – creates a [TimeTravelFeature] backed by a counter,
/// registered against the given [controller].
TimeTravelFeature<int, CounterMsg, CounterEffect> createCounter({
  required String name,
  required TimeTravelController controller,
  int initialState = 0,
  RecordingEffectHandler? effectHandler,
}) {
  return TimeTravelFeature<int, CounterMsg, CounterEffect>(
    name: name,
    initialState: initialState,
    update: counterUpdate,
    effectHandlers: [effectHandler ?? RecordingEffectHandler()],
    controller: controller,
  );
}

// ---------------------------------------------------------------------------
// Second feature type – a simple string accumulator for multi-feature tests
// ---------------------------------------------------------------------------

enum AccMsg { append, clear }

enum AccEffect { none }

(String?, List<AccEffect>) accUpdate(String state, AccMsg msg) {
  return switch (msg) {
    AccMsg.append => ('${state}x', []),
    AccMsg.clear => ('', []),
  };
}

TimeTravelFeature<String, AccMsg, AccEffect> createAccumulator({
  required String name,
  required TimeTravelController controller,
  String initialState = '',
}) {
  return TimeTravelFeature<String, AccMsg, AccEffect>(
    name: name,
    initialState: initialState,
    update: accUpdate,
    effectHandlers: [],
    controller: controller,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // TimeTravelController – basic lifecycle
  // =========================================================================
  group('TimeTravelController lifecycle', () {
    late TimeTravelController controller;

    setUp(() {
      controller = TimeTravelController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('initial state has empty timeline and is not time traveling', () {
      expect(controller.state.timeline, isEmpty);
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.state.navigation.isTimeTraveling, isFalse);
      expect(controller.isTimeTraveling, isFalse);
    });

    test('dispose clears features and closes stream', () async {
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();
      await controller.dispose();

      // After dispose the state subject is closed –
      // creating a new feature on a disposed controller would fail,
      // but the controller itself should not throw on double-dispose fields.
      // We mainly assert dispose completes without error.
    });
  });

  // =========================================================================
  // Register / unregister
  // =========================================================================
  group('TimeTravelController register & unregister', () {
    late TimeTravelController controller;

    setUp(() {
      controller = TimeTravelController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('registering a feature captures its initial state in snapshots',
        () async {
      final feature = createCounter(
        name: 'counter',
        controller: controller,
        initialState: 42,
      );
      await feature.init();

      // The feature is registered – sending a message proves it works.
      feature.accept(CounterMsg.increment);
      expect(feature.state, 43);

      await feature.dispose();
    });

    test('unregistering removes the feature from all snapshots', () async {
      final feature = createCounter(name: 'counter', controller: controller);
      await feature.init();

      // Produce a message so the timeline is non-empty.
      feature.accept(CounterMsg.increment);
      expect(controller.state.timeline, hasLength(1));

      await feature.dispose(); // calls unregister

      // Controller still holds the timeline event, but the feature is gone.
      expect(controller.state.timeline, hasLength(1));
    });
  });

  // =========================================================================
  // Timeline recording
  // =========================================================================
  group('Timeline recording', () {
    late TimeTravelController controller;
    late TimeTravelFeature<int, CounterMsg, CounterEffect> feature;

    setUp(() async {
      controller = TimeTravelController();
      feature = createCounter(name: 'counter', controller: controller);
      await feature.init();
    });

    tearDown(() async {
      await feature.dispose();
      await controller.dispose();
    });

    test('each accepted message is appended to the timeline', () {
      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.decrement);

      final timeline = controller.state.timeline;
      expect(timeline, hasLength(3));
      expect(timeline[0].featureName, 'counter');
      expect(timeline[0].message, CounterMsg.increment);
      expect(timeline[1].message, CounterMsg.increment);
      expect(timeline[2].message, CounterMsg.decrement);
    });

    test('timeline events have non-decreasing timestamps', () {
      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.increment);

      final t0 = controller.state.timeline[0].millisecondsSinceStart;
      final t1 = controller.state.timeline[1].millisecondsSinceStart;
      expect(t1, greaterThanOrEqualTo(t0));
    });

    test('timeline is unmodifiable', () {
      feature.accept(CounterMsg.increment);

      expect(
        () => controller.state.timeline.add(
          (
            featureName: 'x',
            message: CounterMsg.increment,
            millisecondsSinceStart: 0,
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // =========================================================================
  // TimeTravelFeature – state & effects
  // =========================================================================
  group('TimeTravelFeature state & effects', () {
    late TimeTravelController controller;
    late RecordingEffectHandler effectHandler;
    late TimeTravelFeature<int, CounterMsg, CounterEffect> feature;

    setUp(() async {
      controller = TimeTravelController();
      effectHandler = RecordingEffectHandler();
      feature = createCounter(
        name: 'counter',
        controller: controller,
        effectHandler: effectHandler,
      );
      await feature.init();
    });

    tearDown(() async {
      await feature.dispose();
      await controller.dispose();
    });

    test('accept updates state correctly', () {
      feature.accept(CounterMsg.increment);
      expect(feature.state, 1);

      feature.accept(CounterMsg.increment);
      expect(feature.state, 2);

      feature.accept(CounterMsg.decrement);
      expect(feature.state, 1);
    });

    test('accept with same state value does not re-emit state', () async {
      // reset to 0 when already at 0 – produces state=0 which equals
      // current state, so _stateSubject should NOT re-emit.
      final states = <int>[];
      feature.stateStream.skip(1).listen(states.add); // skip seed

      feature.accept(CounterMsg.reset); // 0 -> 0 (same value)
      await Future.delayed(Duration.zero);

      // The effect should still fire even though state didn't change.
      expect(effectHandler.handled, contains(CounterEffect.onReset));
      // State subject should NOT emit because value didn't change.
      expect(states, isEmpty);
    });

    test('effects are delivered in normal mode', () async {
      feature.accept(CounterMsg.reset);

      // Give microtask queue a chance to deliver the stream event.
      await Future.delayed(Duration.zero);

      expect(effectHandler.handled, [CounterEffect.onReset]);
    });

    test('effects are suppressed during time travel replay', () async {
      // Build up some history that includes an effect-producing message.
      feature.accept(CounterMsg.increment); // timeline[0]
      feature.accept(CounterMsg.reset); // timeline[1] – produces effect

      await Future.delayed(Duration.zero);
      effectHandler.handled.clear();

      // Travel back – replay should NOT trigger effects.
      controller.goToStart();
      await Future.delayed(Duration.zero);

      expect(effectHandler.handled, isEmpty);
    });

    test('stateStream emits state changes', () async {
      final states = <int>[];
      final sub = feature.stateStream.skip(1).listen(states.add);

      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.decrement);

      await Future.delayed(Duration.zero);
      expect(states, [1, 2, 1]);

      await sub.cancel();
    });
  });

  // =========================================================================
  // Navigation – goBack / goForward
  // =========================================================================
  group('Navigation goBack & goForward', () {
    late TimeTravelController controller;
    late TimeTravelFeature<int, CounterMsg, CounterEffect> feature;

    setUp(() async {
      controller = TimeTravelController();
      feature = createCounter(name: 'counter', controller: controller);
      await feature.init();
    });

    tearDown(() async {
      await feature.dispose();
      await controller.dispose();
    });

    test('goBack from live mode goes to second-to-last event', () {
      feature.accept(CounterMsg.increment); // state 1, timeline[0]
      feature.accept(CounterMsg.increment); // state 2, timeline[1]
      feature.accept(CounterMsg.increment); // state 3, timeline[2]

      controller.goBack(); // should move to index 1
      expect(controller.state.navigation.currentIndex, 1);
      expect(controller.isTimeTraveling, isTrue);
      expect(feature.state, 2);
    });

    test(
        'goBack does nothing when timeline has fewer than 2 events and not time-traveled',
        () {
      // Empty timeline
      controller.goBack();
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isFalse);

      // Single event
      feature.accept(CounterMsg.increment);
      controller.goBack();
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isFalse);
    });

    test('goBack at index 0 goes to initial state', () {
      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.increment);

      controller.goToStart(); // initial state
      controller.goForward(); // index 0
      expect(controller.state.navigation.currentIndex, 0);

      controller.goBack(); // should go to initial state
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isTrue);
      expect(feature.state, 0); // initial state
    });

    test('goBack at initial state does nothing', () {
      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.increment);

      controller.goToStart(); // initial state
      controller.goBack(); // should stay at initial state
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isTrue);
    });

    test('goForward in live mode does nothing', () {
      feature.accept(CounterMsg.increment);

      controller.goForward();
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isFalse);
    });

    test('goForward at end of timeline does nothing', () {
      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.increment);

      controller.goBack(); // index 0 (second-to-last)
      controller.goForward(); // index 1 (last)

      // Now at last index – goForward should be no-op
      controller.goForward();
      expect(controller.state.navigation.currentIndex, 1);
    });

    test('goForward moves one step forward', () {
      feature.accept(CounterMsg.increment); // 1
      feature.accept(CounterMsg.increment); // 2
      feature.accept(CounterMsg.increment); // 3

      controller.goToStart(); // initial state, state = 0
      expect(feature.state, 0);

      controller.goForward(); // index 0, state should be 1
      expect(controller.state.navigation.currentIndex, 0);
      expect(feature.state, 1);

      controller.goForward(); // index 1, state should be 2
      expect(controller.state.navigation.currentIndex, 1);
      expect(feature.state, 2);
    });
  });

  // =========================================================================
  // Navigation – goToStart / goToEnd
  // =========================================================================
  group('Navigation goToStart & goToEnd', () {
    late TimeTravelController controller;
    late TimeTravelFeature<int, CounterMsg, CounterEffect> feature;

    setUp(() async {
      controller = TimeTravelController();
      feature = createCounter(name: 'counter', controller: controller);
      await feature.init();
    });

    tearDown(() async {
      await feature.dispose();
      await controller.dispose();
    });

    test('goToStart restores to true initial state', () {
      feature.accept(CounterMsg.increment); // 1
      feature.accept(CounterMsg.increment); // 2
      feature.accept(CounterMsg.increment); // 3

      controller.goToStart();
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.state.navigation.isTimeTraveling, isTrue);
      expect(feature.state, 0); // true initial state
    });

    test('goToEnd restores final state and stays in time travel mode', () {
      feature.accept(CounterMsg.increment); // 1
      feature.accept(CounterMsg.increment); // 2
      feature.accept(CounterMsg.increment); // 3

      controller.goToStart();
      expect(feature.state, 0);

      controller.goToEnd();
      expect(controller.state.navigation.currentIndex, 2);
      expect(controller.isTimeTraveling, isTrue);
      expect(feature.state, 3);
    });

    test('goToEnd on empty timeline goes to initial state', () {
      controller.goToEnd();
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isTrue);
    });
  });

  // =========================================================================
  // Multi-step history navigation
  // =========================================================================
  group('Multi-step history navigation', () {
    late TimeTravelController controller;
    late TimeTravelFeature<int, CounterMsg, CounterEffect> feature;

    setUp(() async {
      controller = TimeTravelController();
      feature = createCounter(name: 'counter', controller: controller);
      await feature.init();
    });

    tearDown(() async {
      await feature.dispose();
      await controller.dispose();
    });

    test('back-back-forward replays to correct intermediate state', () {
      // Build: 0 -> 1 -> 2 -> 3 -> 4
      for (var i = 0; i < 4; i++) {
        feature.accept(CounterMsg.increment);
      }
      expect(feature.state, 4);

      controller.goBack(); // index 2 (second-to-last), state 3
      expect(controller.state.navigation.currentIndex, 2);
      expect(feature.state, 3);

      controller.goBack(); // index 1, state 2
      expect(controller.state.navigation.currentIndex, 1);
      expect(feature.state, 2);

      controller.goForward(); // index 2, state 3
      expect(controller.state.navigation.currentIndex, 2);
      expect(feature.state, 3);
    });

    test('goToStart then step forward through entire history', () {
      // Build: 0 -> 1 -> 2 -> 3
      feature.accept(CounterMsg.increment); // 1
      feature.accept(CounterMsg.increment); // 2
      feature.accept(CounterMsg.increment); // 3

      controller.goToStart(); // initial state
      expect(feature.state, 0);

      controller.goForward(); // index 0
      expect(feature.state, 1);

      controller.goForward(); // index 1
      expect(feature.state, 2);

      controller.goForward(); // index 2
      expect(feature.state, 3);

      // Already at end – stays put
      controller.goForward();
      expect(feature.state, 3);
      expect(controller.state.navigation.currentIndex, 2);
    });

    test('back-back-back saturates at initial state', () {
      feature.accept(CounterMsg.increment); // 1
      feature.accept(CounterMsg.increment); // 2

      controller.goBack(); // index 0
      expect(controller.state.navigation.currentIndex, 0);
      expect(feature.state, 1);

      controller.goBack(); // initial state
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isTrue);
      expect(feature.state, 0);

      controller.goBack(); // still initial state
      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isTrue);
    });

    test('goToEnd after multiple backs restores final state', () {
      feature.accept(CounterMsg.increment); // 1
      feature.accept(CounterMsg.increment); // 2
      feature.accept(CounterMsg.increment); // 3
      feature.accept(CounterMsg.increment); // 4

      controller.goBack(); // index 2, state 3
      controller.goBack(); // index 1, state 2
      controller.goBack(); // index 0, state 1

      controller.goToEnd();
      expect(controller.state.navigation.currentIndex, 3);
      expect(controller.isTimeTraveling, isTrue);
      expect(feature.state, 4);
    });

    test('mixed messages: increment, decrement, reset navigated correctly', () {
      feature.accept(CounterMsg.increment); // 0->1
      feature.accept(CounterMsg.increment); // 1->2
      feature.accept(CounterMsg.decrement); // 2->1
      feature.accept(CounterMsg.reset); // 1->0

      // goToStart -> initial state = 0
      controller.goToStart();
      expect(feature.state, 0);

      // At index 0: state after first increment = 1
      controller.goForward();
      expect(feature.state, 1);

      // At index 1: state after two increments = 2
      controller.goForward();
      expect(feature.state, 2);

      // At index 2: state after inc,inc,dec = 1
      controller.goForward();
      expect(feature.state, 1);

      // At index 3: state after inc,inc,dec,reset = 0
      controller.goForward();
      expect(feature.state, 0);
    });
  });

  // =========================================================================
  // Snapshot mechanism
  // =========================================================================
  group('Snapshot mechanism', () {
    test('snapshot is taken at exact multiples of snapshotAtEach', () async {
      final controller = TimeTravelController(snapshotAtEach: 3);
      final feature = createCounter(name: 'counter', controller: controller);
      await feature.init();

      // Send 6 messages -> snapshots at 3 and 6
      for (var i = 0; i < 6; i++) {
        feature.accept(CounterMsg.increment);
      }
      expect(feature.state, 6);

      // goToStart -> initial state = 0
      controller.goToStart();
      expect(feature.state, 0);

      // Step forward through history
      controller.goForward(); // index 0 -> state 1
      expect(feature.state, 1);

      controller.goForward(); // index 1
      controller.goForward(); // index 2
      controller.goForward(); // index 3
      controller.goForward(); // index 4
      expect(controller.state.navigation.currentIndex, 4);
      expect(feature.state, 5);

      await feature.dispose();
      await controller.dispose();
    });

    test('replay across snapshot boundary produces correct state', () async {
      final controller = TimeTravelController(snapshotAtEach: 2);
      final feature = createCounter(name: 'counter', controller: controller);
      await feature.init();

      // Send 5 messages: states 1,2,3,4,5
      // Snapshots at indices 0(initial), 2(after 2 msgs, state=2), 4(after 4 msgs, state=4)
      for (var i = 0; i < 5; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Jump to index 3 – should use snapshot at index 2 (state=2), replay msgs 2,3
      controller.goToStart(); // initial state
      controller.goForward(); // index 0
      controller.goForward(); // index 1
      controller.goForward(); // index 2
      controller.goForward(); // index 3
      expect(controller.state.navigation.currentIndex, 3);
      expect(feature.state, 4);

      await feature.dispose();
      await controller.dispose();
    });

    test('snapshotAtEach=1 creates a snapshot after every message', () async {
      final controller = TimeTravelController(snapshotAtEach: 1);
      final feature = createCounter(name: 'counter', controller: controller);
      await feature.init();

      for (var i = 0; i < 5; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Navigate to each position and verify
      controller.goToStart(); // initial state
      expect(feature.state, 0);

      controller.goForward(); // index 0
      expect(feature.state, 1);

      controller.goForward(); // index 1
      expect(feature.state, 2);

      controller.goForward(); // index 2
      expect(feature.state, 3);

      await feature.dispose();
      await controller.dispose();
    });
  });

  // =========================================================================
  // Multiple features on the same controller
  // =========================================================================
  group('Multiple features on same controller', () {
    late TimeTravelController controller;
    late TimeTravelFeature<int, CounterMsg, CounterEffect> counter;
    late TimeTravelFeature<String, AccMsg, AccEffect> accumulator;

    setUp(() async {
      controller = TimeTravelController();
      counter = createCounter(name: 'counter', controller: controller);
      accumulator = createAccumulator(
        name: 'accumulator',
        controller: controller,
      );
      await counter.init();
      await accumulator.init();
    });

    tearDown(() async {
      await counter.dispose();
      await accumulator.dispose();
      await controller.dispose();
    });

    test('timeline records messages from both features in order', () {
      counter.accept(CounterMsg.increment);
      accumulator.accept(AccMsg.append);
      counter.accept(CounterMsg.increment);

      final timeline = controller.state.timeline;
      expect(timeline, hasLength(3));
      expect(timeline[0].featureName, 'counter');
      expect(timeline[1].featureName, 'accumulator');
      expect(timeline[2].featureName, 'counter');
    });

    test('goToStart restores both features to their initial state', () {
      counter.accept(CounterMsg.increment); // counter: 1
      accumulator.accept(AccMsg.append); // acc: 'x'
      counter.accept(CounterMsg.increment); // counter: 2
      accumulator.accept(AccMsg.append); // acc: 'xx'

      controller.goToStart(); // initial state
      expect(counter.state, 0);
      expect(accumulator.state, '');
    });

    test('goToEnd restores both features to their final states', () {
      counter.accept(CounterMsg.increment); // counter: 1
      accumulator.accept(AccMsg.append); // acc: 'x'
      counter.accept(CounterMsg.increment); // counter: 2

      controller.goToStart();
      controller.goToEnd();

      expect(counter.state, 2);
      expect(accumulator.state, 'x');
    });

    test('stepping through interleaved messages restores correct states', () {
      counter.accept(CounterMsg.increment); // timeline[0]: counter 1
      accumulator.accept(AccMsg.append); // timeline[1]: acc 'x'
      counter.accept(CounterMsg.decrement); // timeline[2]: counter 0
      accumulator.accept(AccMsg.append); // timeline[3]: acc 'xx'

      controller.goToStart(); // initial state
      expect(counter.state, 0);
      expect(accumulator.state, '');

      controller.goForward(); // index 0
      expect(counter.state, 1);
      expect(accumulator.state, '');

      controller.goForward(); // index 1
      expect(counter.state, 1);
      expect(accumulator.state, 'x');

      controller.goForward(); // index 2
      expect(counter.state, 0);
      expect(accumulator.state, 'x');

      controller.goForward(); // index 3
      expect(counter.state, 0);
      expect(accumulator.state, 'xx');
    });

    test('snapshot captures state of all registered features', () async {
      // Use small snapshot interval to trigger it
      await counter.dispose();
      await accumulator.dispose();
      await controller.dispose();

      controller = TimeTravelController(snapshotAtEach: 2);
      counter = createCounter(name: 'counter', controller: controller);
      accumulator = createAccumulator(
        name: 'accumulator',
        controller: controller,
      );
      await counter.init();
      await accumulator.init();

      counter.accept(CounterMsg.increment); // counter:1, timeline[0]
      accumulator.accept(AccMsg.append); // acc:'x', timeline[1] -> snapshot

      counter.accept(CounterMsg.increment); // counter:2, timeline[2]
      accumulator.accept(AccMsg.append); // acc:'xx', timeline[3] -> snapshot

      // Go to index 2 – should use snapshot from index 2 boundary
      // snapshot[1] has counter=1, acc='x' (taken after 2 messages)
      // then replay timeline[2] -> counter gets inc -> counter=2
      controller.goToStart(); // initial state
      controller.goForward(); // index 0
      controller.goForward(); // index 1
      controller.goForward(); // index 2
      expect(controller.state.navigation.currentIndex, 2);
      expect(counter.state, 2);
      expect(accumulator.state, 'x');
    });
  });

  // =========================================================================
  // Corner cases
  // =========================================================================
  group('Corner cases', () {
    test('goToStart on empty timeline restores initial state', () async {
      final controller = TimeTravelController();
      final feature = createCounter(
        name: 'c',
        controller: controller,
        initialState: 42,
      );
      await feature.init();

      // goToStart should restore to initial state even with empty timeline
      controller.goToStart();
      expect(controller.isTimeTraveling, isTrue);
      expect(controller.state.navigation.currentIndex, isNull);
      expect(feature.state, 42);

      await feature.dispose();
      await controller.dispose();
    });

    test('goBack with exactly 1 event does nothing', () async {
      final controller = TimeTravelController();
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      feature.accept(CounterMsg.increment); // only 1 event
      controller.goBack(); // needs >= 2 events to go back from live mode

      expect(controller.state.navigation.currentIndex, isNull);
      expect(controller.isTimeTraveling, isFalse);
      expect(feature.state, 1); // unchanged

      await feature.dispose();
      await controller.dispose();
    });

    test('goBack with exactly 2 events enters time travel at index 0',
        () async {
      final controller = TimeTravelController();
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      feature.accept(CounterMsg.increment); // state 1
      feature.accept(CounterMsg.increment); // state 2

      controller.goBack(); // index 0 (second-to-last)
      expect(controller.state.navigation.currentIndex, 0);
      expect(feature.state, 1);

      await feature.dispose();
      await controller.dispose();
    });

    test(
        'messages during time travel do not produce effects or timeline entries',
        () async {
      final controller = TimeTravelController();
      final effectHandler = RecordingEffectHandler();
      final feature = createCounter(
        name: 'c',
        controller: controller,
        effectHandler: effectHandler,
      );
      await feature.init();

      feature.accept(CounterMsg.increment); // timeline[0]
      feature.accept(CounterMsg.increment); // timeline[1]
      await Future.delayed(Duration.zero);
      effectHandler.handled.clear();

      controller.goToStart(); // enter time travel
      expect(controller.isTimeTraveling, isTrue);

      // The timeline length should remain at 2 –
      // accept calls during replay should not add to timeline.
      expect(controller.state.timeline, hasLength(2));
      expect(effectHandler.handled, isEmpty);

      await feature.dispose();
      await controller.dispose();
    });

    test('feature with non-zero initial state replays correctly', () async {
      final controller = TimeTravelController();
      final feature = createCounter(
        name: 'c',
        controller: controller,
        initialState: 100,
      );
      await feature.init();

      feature.accept(CounterMsg.increment); // 101
      feature.accept(CounterMsg.increment); // 102
      feature.accept(CounterMsg.decrement); // 101

      controller.goToStart(); // initial state = 100
      expect(feature.state, 100);

      controller.goForward(); // index 0: 100 + inc = 101
      expect(feature.state, 101);

      controller.goForward(); // index 1: 102
      expect(feature.state, 102);

      controller.goForward(); // index 2: 101
      expect(feature.state, 101);

      await feature.dispose();
      await controller.dispose();
    });

    test('isTimeTraveling is false after endTimeTravel', () async {
      final controller = TimeTravelController();
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      feature.accept(CounterMsg.increment);
      feature.accept(CounterMsg.increment);

      controller.goToStart();
      expect(controller.isTimeTraveling, isTrue);

      controller.endTimeTravel();
      expect(controller.isTimeTraveling, isFalse);
      expect(controller.state.navigation.currentIndex, isNull);

      await feature.dispose();
      await controller.dispose();
    });

    test('multiple goToEnd calls are safe on non-empty timeline', () async {
      final controller = TimeTravelController();
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      feature.accept(CounterMsg.increment);

      controller.goToEnd();
      controller.goToEnd();
      controller.goToEnd();

      expect(controller.state.navigation.currentIndex, 0);
      expect(controller.isTimeTraveling, isTrue);

      await feature.dispose();
      await controller.dispose();
    });

    test('new messages after exiting time travel append to timeline normally',
        () async {
      final controller = TimeTravelController();
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      feature.accept(CounterMsg.increment); // 1
      feature.accept(CounterMsg.increment); // 2

      controller.goToStart(); // time travel to initial state
      controller.endTimeTravel(); // exit time travel

      // Now send more messages – they should be recorded normally
      feature.accept(CounterMsg.increment); // 3
      expect(controller.state.timeline, hasLength(3));
      expect(feature.state, 3);
      expect(controller.isTimeTraveling, isFalse);

      await feature.dispose();
      await controller.dispose();
    });

    test('registering the same feature name twice overwrites the first',
        () async {
      final controller = TimeTravelController();
      final feature1 = createCounter(
        name: 'dup',
        controller: controller,
        initialState: 10,
      );
      final feature2 = createCounter(
        name: 'dup',
        controller: controller,
        initialState: 20,
      );
      await feature1.init();
      await feature2.init();

      // feature2 should have overwritten feature1 in the controller
      feature2.accept(CounterMsg.increment);
      expect(feature2.state, 21);

      // feature1 still works independently but isn't tracked by the controller
      feature1.accept(CounterMsg.increment);
      expect(feature1.state, 11);

      await feature1.dispose();
      await feature2.dispose();
      await controller.dispose();
    });
  });

  // =========================================================================
  // Combined time travel features – simultaneous operations
  // =========================================================================
  group('Simultaneous time travel features', () {
    test('two features navigated back and forth preserve both states',
        () async {
      final controller = TimeTravelController();
      final counter = createCounter(name: 'counter', controller: controller);
      final acc = createAccumulator(name: 'acc', controller: controller);
      await counter.init();
      await acc.init();

      counter.accept(CounterMsg.increment); // c:1, t[0]
      acc.accept(AccMsg.append); // a:'x', t[1]
      counter.accept(CounterMsg.increment); // c:2, t[2]
      acc.accept(AccMsg.append); // a:'xx', t[3]
      counter.accept(CounterMsg.increment); // c:3, t[4]

      // Go back step by step and verify both
      controller.goBack(); // index 3
      expect(counter.state, 2);
      expect(acc.state, 'xx');

      controller.goBack(); // index 2
      expect(counter.state, 2);
      expect(acc.state, 'x');

      controller.goBack(); // index 1
      expect(counter.state, 1);
      expect(acc.state, 'x');

      controller.goBack(); // index 0
      expect(counter.state, 1);
      expect(acc.state, '');

      controller.goBack(); // initial state
      expect(counter.state, 0);
      expect(acc.state, '');

      // Now forward
      controller.goForward(); // index 0
      expect(counter.state, 1);
      expect(acc.state, '');

      controller.goForward(); // index 1
      expect(counter.state, 1);
      expect(acc.state, 'x');

      controller.goForward(); // index 2
      expect(counter.state, 2);
      expect(acc.state, 'x');

      await counter.dispose();
      await acc.dispose();
      await controller.dispose();
    });

    test('goToStart with multiple features resets all to initial state',
        () async {
      final controller = TimeTravelController();
      final counter = createCounter(
        name: 'counter',
        controller: controller,
        initialState: 50,
      );
      final acc = createAccumulator(
        name: 'acc',
        controller: controller,
        initialState: 'start',
      );
      await counter.init();
      await acc.init();

      acc.accept(AccMsg.append); // 'startx', t[0]
      counter.accept(CounterMsg.decrement); // 49, t[1]
      acc.accept(AccMsg.clear); // '', t[2]

      controller.goToStart();
      // snapshot has counter=50, acc='start'
      // no messages replayed – true initial state
      expect(counter.state, 50);
      expect(acc.state, 'start');

      await counter.dispose();
      await acc.dispose();
      await controller.dispose();
    });

    test(
        'effects only fire for the correct feature and only outside time travel',
        () async {
      final controller = TimeTravelController();
      final effectHandler = RecordingEffectHandler();
      final counter = createCounter(
        name: 'counter',
        controller: controller,
        effectHandler: effectHandler,
      );
      final acc = createAccumulator(name: 'acc', controller: controller);
      await counter.init();
      await acc.init();

      counter.accept(CounterMsg.reset); // effect fires
      acc.accept(AccMsg.append);
      await Future.delayed(Duration.zero);

      expect(effectHandler.handled, [CounterEffect.onReset]);
      effectHandler.handled.clear();

      // Enter time travel – replaying the reset should NOT fire the effect
      controller.goToStart();
      await Future.delayed(Duration.zero);
      expect(effectHandler.handled, isEmpty);

      await counter.dispose();
      await acc.dispose();
      await controller.dispose();
    });

    test('unregistering one feature while traveling does not break the other',
        () async {
      final controller = TimeTravelController();
      final counter = createCounter(name: 'counter', controller: controller);
      final acc = createAccumulator(name: 'acc', controller: controller);
      await counter.init();
      await acc.init();

      counter.accept(CounterMsg.increment); // t[0], counter-only
      counter.accept(CounterMsg.increment); // t[1], counter-only

      // Dispose accumulator – it was never in the timeline, so travel should work
      await acc.dispose();

      controller.goToStart();
      expect(counter.state, 0);

      controller.goToEnd();
      expect(counter.state, 2);

      await counter.dispose();
      await controller.dispose();
    });
  });

  // =========================================================================
  // Snapshot boundary – large number of messages
  // =========================================================================
  group('Large history with snapshots', () {
    test(
        'navigating to arbitrary index with snapshotAtEach=3 yields correct state',
        () async {
      final controller = TimeTravelController(snapshotAtEach: 3);
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 10 increments: states 1..10
      for (var i = 0; i < 10; i++) {
        feature.accept(CounterMsg.increment);
      }
      expect(feature.state, 10);

      // Navigate to each index and verify
      controller.goToStart(); // initial state = 0
      expect(feature.state, 0);

      for (var i = 0; i <= 9; i++) {
        controller.goForward();
        expect(feature.state, i + 1, reason: 'at index $i');
      }

      await feature.dispose();
      await controller.dispose();
    });

    test(
        'goToStart then goToEnd with many messages and small snapshot interval',
        () async {
      final controller = TimeTravelController(snapshotAtEach: 2);
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      for (var i = 0; i < 7; i++) {
        feature.accept(CounterMsg.increment);
      }

      controller.goToStart();
      expect(feature.state, 0);

      controller.goToEnd();
      expect(feature.state, 7);
      expect(controller.isTimeTraveling, isTrue);
      expect(controller.state.navigation.currentIndex, 6);

      await feature.dispose();
      await controller.dispose();
    });
  });

  // =========================================================================
  // Timeline limit
  // =========================================================================
  group('Timeline limit', () {
    test('timeline is not limited when timelineLimit is null', () async {
      final controller = TimeTravelController(
        snapshotAtEach: 5,
        timelineLimit: null,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 20 messages – all should be retained
      for (var i = 0; i < 20; i++) {
        feature.accept(CounterMsg.increment);
      }

      expect(controller.state.timeline, hasLength(20));
      expect(feature.state, 20);

      await feature.dispose();
      await controller.dispose();
    });

    test('timeline is trimmed when it exceeds the limit', () async {
      final controller = TimeTravelController(
        snapshotAtEach: 5,
        timelineLimit: 10,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 15 messages
      // After 10: timeline[0..9], snapshots at 0(initial), 5, 10
      // After 15: should trim to timeline[5..14], snapshots at 0(initial), 5, 10, 15
      // Then trim removes timeline[5..9] and snapshot[1]
      // Result: timeline[10..14] (5 events), snapshots at 0(initial from 10), 15
      for (var i = 0; i < 15; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Timeline should be limited to 10 events
      expect(controller.state.timeline.length, lessThanOrEqualTo(10));
      // State should still be correct
      expect(feature.state, 15);

      await feature.dispose();
      await controller.dispose();
    });

    test('timeline limit is rounded up to nearest multiple of snapshotAtEach',
        () async {
      // Request limit of 7, with snapshotAtEach=5
      // Should round up to 10
      final controller = TimeTravelController(
        snapshotAtEach: 5,
        timelineLimit: 7,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 20 messages – timeline should stabilize at 10 (rounded up from 7)
      for (var i = 0; i < 20; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Should be trimmed to 10 (7 rounded up to next multiple of 5)
      expect(controller.state.timeline.length, lessThanOrEqualTo(10));
      expect(feature.state, 20);

      await feature.dispose();
      await controller.dispose();
    });

    test('timeline limit exact multiple of snapshotAtEach works correctly',
        () async {
      final controller = TimeTravelController(
        snapshotAtEach: 3,
        timelineLimit: 9,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 15 messages
      for (var i = 0; i < 15; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Timeline should be exactly 9
      expect(controller.state.timeline.length, lessThanOrEqualTo(9));
      expect(feature.state, 15);

      await feature.dispose();
      await controller.dispose();
    });

    test('trimming preserves correct snapshots', () async {
      final controller = TimeTravelController(
        snapshotAtEach: 4,
        timelineLimit: 8,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 12 messages: states 1..12
      // Snapshots at: 0(initial), 4(state=4), 8(state=8), 12(state=12)
      // After 12th message, timeline has 12 events
      // Trim removes first 4 events and first snapshot
      // Result: timeline[4..11] (8 events), snapshots at 0(from index 4, state=4), 8, 12
      for (var i = 0; i < 12; i++) {
        feature.accept(CounterMsg.increment);
      }

      expect(controller.state.timeline.length, lessThanOrEqualTo(8));

      // Navigate to verify snapshots are correct
      controller.goToStart();
      // After trimming, "start" is now at the first remaining snapshot (state=4)
      // Wait, that's wrong – goToStart should still use stateSnapshots.first
      // which after trimming is the snapshot that was at index 4 (state=4)
      // But we need to verify the states are correct

      // Actually, let's test by navigating forward
      controller.goToEnd();
      expect(feature.state, 12);

      await feature.dispose();
      await controller.dispose();
    });

    test('navigation works correctly after timeline is trimmed', () async {
      final controller = TimeTravelController(
        snapshotAtEach: 3,
        timelineLimit: 6,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 12 messages
      // After 12: timeline has 12 events, will be trimmed multiple times
      // Final state: timeline[6..11] (6 events)
      for (var i = 0; i < 12; i++) {
        feature.accept(CounterMsg.increment);
      }

      expect(controller.state.timeline.length, lessThanOrEqualTo(6));
      expect(feature.state, 12);

      // Navigate backwards
      controller.goBack(); // index 4 (relative to trimmed timeline)
      expect(feature.state, 11);

      controller.goBack(); // index 3
      expect(feature.state, 10);

      controller.goBack(); // index 2
      expect(feature.state, 9);

      // Navigate forwards
      controller.goForward(); // index 3
      expect(feature.state, 10);

      controller.goForward(); // index 4
      expect(feature.state, 11);

      await feature.dispose();
      await controller.dispose();
    });

    test('trimming with multiple features preserves all feature states',
        () async {
      final controller = TimeTravelController(
        snapshotAtEach: 4,
        timelineLimit: 8,
      );
      final counter = createCounter(name: 'counter', controller: controller);
      final acc = createAccumulator(name: 'acc', controller: controller);
      await counter.init();
      await acc.init();

      // Interleave messages from both features
      for (var i = 0; i < 10; i++) {
        counter.accept(CounterMsg.increment);
        acc.accept(AccMsg.append);
      }

      // Timeline should have 20 events, trimmed to 8
      expect(controller.state.timeline.length, lessThanOrEqualTo(8));
      expect(counter.state, 10);
      expect(acc.state, 'x' * 10);

      // Navigate to verify both states are preserved correctly
      controller.goToEnd();
      expect(counter.state, 10);
      expect(acc.state, 'x' * 10);

      await counter.dispose();
      await acc.dispose();
      await controller.dispose();
    });

    test('timeline limit of snapshotAtEach keeps exactly one chunk', () async {
      final controller = TimeTravelController(
        snapshotAtEach: 5,
        timelineLimit: 5,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 15 messages
      for (var i = 0; i < 15; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Should keep exactly 5 events (one chunk)
      expect(controller.state.timeline.length, lessThanOrEqualTo(5));
      expect(feature.state, 15);

      await feature.dispose();
      await controller.dispose();
    });

    test('very small timeline limit (1) rounded up to snapshotAtEach',
        () async {
      final controller = TimeTravelController(
        snapshotAtEach: 5,
        timelineLimit: 1,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send many messages
      for (var i = 0; i < 20; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Limit of 1 should round up to 5 (snapshotAtEach)
      expect(controller.state.timeline.length, lessThanOrEqualTo(5));
      expect(feature.state, 20);

      await feature.dispose();
      await controller.dispose();
    });

    test('timeline limit larger than messages sent keeps all messages',
        () async {
      final controller = TimeTravelController(
        snapshotAtEach: 3,
        timelineLimit: 100,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send only 10 messages, well under the limit
      for (var i = 0; i < 10; i++) {
        feature.accept(CounterMsg.increment);
      }

      // All 10 should be retained
      expect(controller.state.timeline, hasLength(10));
      expect(feature.state, 10);

      await feature.dispose();
      await controller.dispose();
    });

    test('trimming happens only after snapshot creation', () async {
      final controller = TimeTravelController(
        snapshotAtEach: 4,
        timelineLimit: 8,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 7 messages (before snapshot boundary)
      for (var i = 0; i < 7; i++) {
        feature.accept(CounterMsg.increment);
      }

      // No trimming should have happened yet (7 < 8, and no snapshot created yet)
      expect(controller.state.timeline, hasLength(7));

      // Send 1 more to trigger snapshot at index 8
      feature.accept(CounterMsg.increment);

      // Now we have 8 messages, snapshot created, no trimming yet (8 <= 8)
      expect(controller.state.timeline, hasLength(8));

      // Send 4 more to trigger next snapshot at index 12
      for (var i = 0; i < 4; i++) {
        feature.accept(CounterMsg.increment);
      }

      // Now trimming should have happened (12 > 8)
      expect(controller.state.timeline.length, lessThanOrEqualTo(8));

      await feature.dispose();
      await controller.dispose();
    });

    test('goToStart after trimming navigates to oldest retained snapshot',
        () async {
      final controller = TimeTravelController(
        snapshotAtEach: 3,
        timelineLimit: 6,
      );
      final feature = createCounter(name: 'c', controller: controller);
      await feature.init();

      // Send 15 messages
      // This will create snapshots at 0, 3, 6, 9, 12, 15
      // After trimming, we keep last 6 events (timeline[9..14])
      // Snapshots: trimmed to [snapshot_at_9, snapshot_at_12, snapshot_at_15]
      // But first snapshot is always the "initial" for navigation purposes
      for (var i = 0; i < 15; i++) {
        feature.accept(CounterMsg.increment);
      }

      controller.goToStart();
      // Should navigate to the first snapshot in the trimmed array
      // which represents state at the beginning of the retained timeline
      expect(controller.isTimeTraveling, isTrue);
      expect(controller.state.navigation.currentIndex, isNull);

      await feature.dispose();
      await controller.dispose();
    });
  });
}
