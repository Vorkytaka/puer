import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:puer/puer.dart';

// ignore: implementation_imports
import 'package:puer/src/feature_base.dart';

final class TimeTravelController {
  static final global = TimeTravelController();
  static bool _globalServiceExtensionRegistered = false;

  final _stateSubject = StateStream.seeded(_initialTimeTravelState);
  final _stopwatch = Stopwatch();

  /// Take a full state snapshot after every [snapshotAtEach] timeline events.
  final int snapshotAtEach;

  /// Maximum number of timeline events to retain.
  ///
  /// When set, the limit is rounded up to the nearest multiple of
  /// [snapshotAtEach] so snapshots and timeline indices stay aligned. When the
  /// limit is reached, the oldest chunk of events (size [snapshotAtEach]) and
  /// its snapshot are trimmed. After trimming, [goToStart] navigates to the
  /// oldest retained snapshot, not the original initial state.
  final int? timelineLimit;

  StreamSubscription? _stateSubscription;

  /// Creates a time travel controller.
  ///
  /// [snapshotAtEach] controls how often state snapshots are captured.
  /// [timelineLimit], when provided, caps the number of timeline events kept in
  /// memory. It is rounded up to the nearest multiple of [snapshotAtEach].
  TimeTravelController({
    this.snapshotAtEach = 100,
    int? timelineLimit,
  }) : timelineLimit = _countTimelineLimit(timelineLimit, snapshotAtEach);

  static int? _countTimelineLimit(int? timelineLimit, int snapshotAtEach) =>
      timelineLimit == null
          ? null
          : ((timelineLimit + snapshotAtEach - 1) ~/ snapshotAtEach) *
              snapshotAtEach;

  TimeTravelStateV2 get state => _stateSubject.value;

  Future<void> dispose() async {
    await _stateSubscription?.cancel();
    await _stateSubject.close();
    _stopwatch.stop();
  }

  bool get isTimeTraveling => _stateSubject.value.navigation.isTimeTraveling;

  /// Serializes the current time travel state to a JSON-compatible map.
  ///
  /// Used by the DevTools extension to read the state via service extension.

  void _ensureServiceExtension() {
    if (_globalServiceExtensionRegistered) {
      return;
    }
    _globalServiceExtensionRegistered = true;

    developer.registerExtension(
      'ext.puer.getTimeTravelState',
      (method, params) async {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(state.toJson()),
        );
      },
    );

    _stateSubscription = _stateSubject.stream.listen((_) {
      developer.postEvent('ext.puer.stateChanged', {});
    });
  }

  void register(String name, TimeTravelFeature feature) {
    _ensureServiceExtension();

    _stateSubject.add(
      state.copyWith(
        features: {
          ...state.features,
          name: feature,
        },
        stateSnapshots: [
          ...state.stateSnapshots.map(
            (snapshot) => {
              ...snapshot,
              name: feature.state,
            },
          ),
        ],
      ),
    );

    if (state.timeline.isEmpty && state.features.length == 1) {
      _stopwatch.reset();
      _stopwatch.start();
    }
  }

  void unregister(String name) {
    _stateSubject.add(
      state.copyWith(
        features: {
          for (final featureName in state.features.keys)
            if (name != featureName) featureName: state.features[featureName]!,
        },
        stateSnapshots: [
          for (final snapshot in state.stateSnapshots)
            {
              for (final featureName in snapshot.keys)
                if (name != featureName) featureName: snapshot[featureName],
            },
        ],
      ),
    );
  }

  /// Records a message in the timeline.
  ///
  /// This is called when a feature processes a message outside time travel mode.
  /// Every [snapshotAtEach] messages, a full state snapshot is taken. If
  /// [timelineLimit] is set and exceeded after creating a snapshot, the oldest
  /// [snapshotAtEach] events and the first snapshot are trimmed from memory.
  void _onMessage(String featureName, message) {
    _stateSubject.add(
      _stateSubject.value.copyWith(
        timeline: [
          ..._stateSubject.value.timeline,
          (
            featureName: featureName,
            message: message,
            millisecondsSinceStart: _stopwatch.elapsedMilliseconds,
          ),
        ],
      ),
    );

    if (state.timeline.length % snapshotAtEach == 0) {
      final states = <String, dynamic>{
        for (final featureName in state.features.keys)
          featureName: state.features[featureName]!.state,
      };

      _stateSubject.add(
        state.copyWith(
          stateSnapshots: [
            ...state.stateSnapshots,
            states,
          ],
        ),
      );

      // Trim timeline if it exceeds the limit
      if (timelineLimit != null && state.timeline.length > timelineLimit!) {
        _stateSubject.add(
          state.copyWith(
            timeline: state.timeline.sublist(snapshotAtEach),
            stateSnapshots: state.stateSnapshots.sublist(1),
          ),
        );
      }
    }
  }

  /// Exit time travel mode and return to live state.
  ///
  /// Restores to the final state (last event in the timeline) before exiting.
  void endTimeTravel() {
    // First restore to final state
    goToEnd();

    // Then exit time travel mode
    _stateSubject.add(
      state.copyWith(
        navigation: (
          currentIndex: null,
          isTimeTraveling: false,
        ),
      ),
    );
  }

  /// Navigate to the initial state.
  ///
  /// If the timeline has been trimmed (due to [timelineLimit]), this navigates
  /// to the oldest retained snapshot, not the original application initial state.
  void goToStart() {
    _moveTo(-1);
  }

  /// Navigate to the final state (last event in the timeline).
  void goToEnd() {
    if (state.timeline.isEmpty) {
      // No events to replay, stay at initial state
      _moveTo(-1);
      return;
    }

    // Restore to final state by replaying all events
    _moveTo(state.timeline.length - 1);
  }

  /// Navigate one step backward in the timeline.
  ///
  /// If not yet time-traveling, enters time travel mode at the second-to-last event.
  /// If already at the initial state (after trimming, the oldest retained snapshot),
  /// does nothing.
  void goBack() {
    final currentIndex = state.navigation.currentIndex;
    final isTimeTraveling = state.navigation.isTimeTraveling;

    if (currentIndex == null && !isTimeTraveling) {
      // Not yet time traveling
      if (state.timeline.length < 2) {
        // Not enough events to step back, do nothing
        return;
      }
      // Start from one step before the end
      _moveTo(state.timeline.length - 2);
    } else if (currentIndex == null && isTimeTraveling) {
      // Already at initial state while time traveling, do nothing
      return;
    } else if (currentIndex == 0) {
      // At first event, go to initial state (null index)
      _moveTo(-1);
    } else {
      // Step back one event
      _moveTo(currentIndex! - 1);
    }
  }

  /// Navigate one step forward in the timeline.
  ///
  /// Does nothing if not in time travel mode or already at the end.
  void goForward() {
    final currentIndex = state.navigation.currentIndex;
    final isTimeTraveling = state.navigation.isTimeTraveling;

    if (!isTimeTraveling) {
      // Not time traveling, do nothing
      return;
    }

    if (currentIndex == null) {
      // At initial state, move to first event
      if (state.timeline.isEmpty) {
        return;
      }
      _moveTo(0);
    } else if (currentIndex >= state.timeline.length - 1) {
      // Already at the end, do nothing
      return;
    } else {
      _moveTo(currentIndex + 1);
    }
  }

  /// Navigate to a specific timeline index.
  void goToIndex(int index) => _moveTo(index);

  /// Internal: Navigate to a specific timeline index.
  ///
  /// [index] can be -1 (initial state) to timeline.length - 1 (final state).
  /// Uses snapshots and replay to reconstruct the state at the given point.
  /// When [index] is -1, restores `stateSnapshots.first` (which is the oldest
  /// retained snapshot if the timeline has been trimmed).
  void _moveTo(int index) {
    assert(index >= -1 && index < _stateSubject.value.timeline.length);

    // Set time travel mode
    // When index is -1, we're at the initial state, represented by null
    _stateSubject.add(
      _stateSubject.value.copyWith(
        navigation: (
          currentIndex: index == -1 ? null : index,
          isTimeTraveling: true,
        ),
      ),
    );

    final snapshotsIndex = index ~/ snapshotAtEach;
    final from = snapshotsIndex * snapshotAtEach;

    final Map<String, dynamic> snapshots;
    if (index == -1) {
      snapshots = state.stateSnapshots.first;
    } else {
      snapshots = state.stateSnapshots[snapshotsIndex];
    }

    for (final featureName in state.features.keys) {
      final featureState = snapshots[featureName];
      final feature = state.features[featureName]!;

      feature._processState(featureState);
    }

    if (index >= 0) {
      for (int i = from; i <= index; i++) {
        final event = _stateSubject.value.timeline[i];
        final feature = state.features[event.featureName]!;
        feature.accept(event.message);
      }
    }
  }
}

abstract interface class TimeTravelFeature<State, Message, Effect>
    implements Feature<State, Message, Effect> {
  String get name;

  factory TimeTravelFeature({
    required String name,
    required State initialState,
    required Update<State, Message, Effect> update,
    List<EffectHandler<Effect, Message>> effectHandlers = const [],
    List<Effect> initialEffects = const [],
    List<Effect> disposableEffects = const [],
    TimeTravelController? controller,
  }) =>
      _TimeTravelFeature(
        name: name,
        initialState: initialState,
        update: update,
        effectHandlers: effectHandlers,
        initialEffects: initialEffects,
        disposableEffects: disposableEffects,
        controller: controller,
      );

  void _processState(State state);
}

final class _TimeTravelFeature<State, Message, Effect>
    extends FeatureBase<State, Message, Effect>
    implements TimeTravelFeature<State, Message, Effect> {
  final TimeTravelController _timeTravelController;
  @override
  final String name;

  _TimeTravelFeature({
    required this.name,
    required super.initialState,
    required super.update,
    required super.effectHandlers,
    super.initialEffects = const [],
    super.disposableEffects = const [],
    TimeTravelController? controller,
  })  : _timeTravelController = controller ?? TimeTravelController.global,
        assert(name.isNotEmpty);

  @override
  FutureOr<void> init() async {
    _timeTravelController.register(name, this);
    return super.init();
  }

  @override
  Future<void> dispose() {
    _timeTravelController.unregister(name);
    return super.dispose();
  }

  /// Overrides accept to suppress effects during time travel mode.
  ///
  /// When time traveling is active, state updates are applied but effects
  /// are not emitted. This prevents side effects during timeline navigation.
  /// Messages are also not recorded to the timeline during time travel.
  @override
  void accept(Message message) {
    final oldState = state;
    final (newState, effects) = update(state, message);

    if (newState != null && state != newState) {
      emitState(newState);
    }

    if (!_timeTravelController.isTimeTraveling) {
      emitTransition(
        oldState: oldState,
        message: message,
        newState: newState,
        effects: effects,
      );

      if (effects.isNotEmpty) {
        effects.forEach(emitEffect);
      }

      _timeTravelController._onMessage(name, message);
    }
  }

  @override
  void _processState(State state) => emitState(state);
}

typedef TimeTravelNavigation = ({
  /// The index of the currently viewed event in the timeline.
  /// `null` means we are viewing the initial state (before any messages).
  int? currentIndex,

  /// Whether we are currently in time travel mode.
  /// When `true`, effects are suppressed and new messages are not recorded.
  bool isTimeTraveling,
});

typedef TimeTravelStateV2 = ({
  List<TimeTravelEventV2> timeline,
  Map<String, TimeTravelFeature> features,
  List<Map<String, dynamic>> stateSnapshots,
  TimeTravelNavigation navigation,
});

TimeTravelStateV2 get _initialTimeTravelState => (
      timeline: const [],
      features: const {},
      stateSnapshots: const [{}],
      navigation: (currentIndex: null, isTimeTraveling: false),
    );

extension on TimeTravelStateV2 {
  TimeTravelStateV2 copyWith({
    List<TimeTravelEventV2>? timeline,
    Map<String, TimeTravelFeature>? features,
    List<Map<String, dynamic>>? stateSnapshots,
    TimeTravelNavigation? navigation,
  }) =>
      (
        timeline: timeline?.toUnmodifiable ?? this.timeline,
        features: features?.toUnmodifiable ?? this.features,
        stateSnapshots: stateSnapshots?.toUnmodifiable ?? this.stateSnapshots,
        navigation: navigation ?? this.navigation,
      );

  Map<String, dynamic> toJson() => {
        'timeline': timeline
            .map(
              (e) => {
                'featureName': e.featureName,
                'message': e.message.toString(),
                'millisecondsSinceStart': e.millisecondsSinceStart,
              },
            )
            .toList(),
        'navigation': {
          'currentIndex': navigation.currentIndex,
          'isTimeTraveling': navigation.isTimeTraveling,
        },
        'features': features.keys.toList(),
      };
}

typedef TimeTravelEventV2<Message> = ({
  String featureName,
  Message message,
  int millisecondsSinceStart,
});

extension<E> on List<E> {
  List<E> get toUnmodifiable => List.unmodifiable(this);
}

extension<K, V> on Map<K, V> {
  Map<K, V> get toUnmodifiable => Map.unmodifiable(this);
}
