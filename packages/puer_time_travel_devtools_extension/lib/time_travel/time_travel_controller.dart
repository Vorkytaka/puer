import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:flutter/cupertino.dart' show State;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show State;
import 'package:flutter/widgets.dart' show State;

import 'time_travel_service.dart';
import 'time_travel_state.dart';

/// Manages the DevTools extension state.
///
/// Connects to the running application via [TimeTravelService],
/// listens for state changes, and exposes a [ValueListenable] for the UI.
final class TimeTravelController {
  final TimeTravelService _service;

  final ValueNotifier<TimeTravelViewState> _state = ValueNotifier(
    const TimeTravelViewState.connecting(),
  );

  StreamSubscription? _stateChangedSubscription;

  TimeTravelController({TimeTravelService? service})
    : _service = service ?? TimeTravelService();

  /// The current view state for the UI to observe.
  ValueListenable<TimeTravelViewState> get state => _state;

  /// Initializes the connection to the running application.
  ///
  /// Should be called once from [State.initState].
  Future<void> init() async {
    try {
      await _service.init();
    } on LibraryNotFound {
      _state.value = const TimeTravelViewState.unavailable();
      return;
    } on Object catch (e) {
      _state.value = TimeTravelViewState.withError(e.toString());
      return;
    }

    _stateChangedSubscription = _service.onStateChanged.listen((_) {
      _refresh();
    });

    await _refresh();
  }

  /// Fetches the latest state from the running application.
  Future<void> _refresh() async {
    try {
      final snapshot = await _service.getState();
      _state.value = TimeTravelViewState.connected(snapshot);
    } on Object catch (e) {
      _state.value = TimeTravelViewState.withError(e.toString());
    }
  }

  /// Manually re-fetch the current state.
  Future<void> refresh() => _refresh();

  // -- Navigation commands --
  // Each command calls the service, then waits for the state change event
  // to trigger a refresh automatically.

  Future<void> goBack() => _service.goBack();

  Future<void> goForward() => _service.goForward();

  Future<void> goToStart() => _service.goToStart();

  Future<void> goToEnd() => _service.goToEnd();

  Future<void> goToIndex(int index) => _service.goToIndex(index);

  Future<void> endTimeTravel() => _service.endTimeTravel();

  void dispose() {
    _stateChangedSubscription?.cancel();
    _service.dispose();
    _state.dispose();
  }
}
