// ignore_for_file: avoid_print

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:puer/puer.dart';

// ==============================================================================
// State
// ==============================================================================

/// Represents the current state of our counter feature.
@immutable
final class CounterState {
  const CounterState({
    required this.count,
    required this.isLoading,
    this.lastSavedCount,
  });

  /// The current count value.
  final int count;

  /// Whether we're currently performing an async operation.
  final bool isLoading;

  /// The last count value that was successfully saved to storage.
  final int? lastSavedCount;

  @override
  String toString() =>
      'CounterState(count: $count, isLoading: $isLoading, lastSaved: $lastSavedCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterState &&
          count == other.count &&
          isLoading == other.isLoading &&
          lastSavedCount == other.lastSavedCount;

  @override
  int get hashCode => Object.hash(count, isLoading, lastSavedCount);
}

// ==============================================================================
// Messages
// ==============================================================================

/// Messages that can be sent to the counter feature.
///
/// Using a sealed class ensures exhaustive pattern matching in the update function.
sealed class CounterMessage {}

/// User requested to increment the counter.
final class Increment extends CounterMessage {
  @override
  String toString() => 'Increment';
}

/// User requested to decrement the counter.
final class Decrement extends CounterMessage {
  @override
  String toString() => 'Decrement';
}

/// User requested to reset the counter to zero.
final class Reset extends CounterMessage {
  @override
  String toString() => 'Reset';
}

/// User requested to load the saved count from storage.
final class LoadSaved extends CounterMessage {
  @override
  String toString() => 'LoadSaved';
}

/// The saved count was successfully loaded from storage.
final class CountLoaded extends CounterMessage {
  CountLoaded(this.count);
  final int count;

  @override
  String toString() => 'CountLoaded($count)';
}

/// The count was successfully saved to storage.
final class CountSaved extends CounterMessage {
  CountSaved(this.count);
  final int count;

  @override
  String toString() => 'CountSaved($count)';
}

/// An error occurred during an async operation.
final class ErrorOccurred extends CounterMessage {
  ErrorOccurred(this.error);
  final String error;

  @override
  String toString() => 'ErrorOccurred($error)';
}

// ==============================================================================
// Effects
// ==============================================================================

/// Side effects that can be triggered by the counter feature.
///
/// Effects are plain data - they describe WHAT should happen, not HOW.
sealed class CounterEffect {}

/// Load the saved count from storage.
final class LoadCount extends CounterEffect {
  @override
  String toString() => 'LoadCount';
}

/// Save the current count to storage.
final class SaveCount extends CounterEffect {
  SaveCount(this.count);
  final int count;

  @override
  String toString() => 'SaveCount($count)';
}

/// Log a message to the console (for demonstration purposes).
final class LogMessage extends CounterEffect {
  LogMessage(this.message);
  final String message;

  @override
  String toString() => 'LogMessage($message)';
}

// ==============================================================================
// Update function (Pure business logic)
// ==============================================================================

/// The update function: the heart of the feature.
///
/// This is a PURE function:
/// - No side effects (no async, no IO, no random, no DateTime.now())
/// - Deterministic (same inputs always produce same outputs)
/// - Easy to test (just call it with state and message)
///
/// All business logic lives here. Side effects are returned as Effect values.
Next<CounterState, CounterEffect> counterUpdate(
  CounterState state,
  CounterMessage message,
) =>
    switch (message) {
      // User actions - modify state and trigger save
      Increment() => next(
          state: CounterState(
            count: state.count + 1,
            isLoading: false,
            lastSavedCount: state.lastSavedCount,
          ),
          effects: [
            SaveCount(state.count + 1),
            LogMessage('Incremented to ${state.count + 1}'),
          ],
        ),
      Decrement() => next(
          state: CounterState(
            count: state.count - 1,
            isLoading: false,
            lastSavedCount: state.lastSavedCount,
          ),
          effects: [
            SaveCount(state.count - 1),
            LogMessage('Decremented to ${state.count - 1}'),
          ],
        ),
      Reset() => next(
          state: const CounterState(
            count: 0,
            isLoading: false,
            lastSavedCount: null,
          ),
          effects: [
            SaveCount(0),
            LogMessage('Reset to 0'),
          ],
        ),

      // Load request - set loading state and trigger load effect
      LoadSaved() => next(
          state: CounterState(
            count: state.count,
            isLoading: true,
            lastSavedCount: state.lastSavedCount,
          ),
          effects: [LoadCount()],
        ),

      // Handler responses - update state based on async results
      CountLoaded(:final count) => next(
          state: CounterState(
            count: count,
            isLoading: false,
            lastSavedCount: count,
          ),
          effects: [LogMessage('Loaded count: $count')],
        ),
      CountSaved(:final count) => next(
          state: CounterState(
            count: state.count,
            isLoading: false,
            lastSavedCount: count,
          ),
        ),
      ErrorOccurred(:final error) => next(
          state: CounterState(
            count: state.count,
            isLoading: false,
            lastSavedCount: state.lastSavedCount,
          ),
          effects: [LogMessage('Error: $error')],
        ),
    };

// ==============================================================================
// Effect handler (Performs actual side effects)
// ==============================================================================

/// Simulated storage service for demonstration.
///
/// In a real app, this would be SharedPreferences, Hive, SQLite, etc.
final class FakeStorage {
  int? _savedCount;

  Future<int?> load() async {
    // Simulate async delay
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _savedCount;
  }

  Future<void> save(int count) async {
    // Simulate async delay
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _savedCount = count;
  }
}

/// Effect handler: executes side effects and emits messages back.
///
/// Handlers should be "dumb" - they translate effects into real-world actions
/// and report results. All business decisions happen in the update function.
final class CounterEffectHandler
    implements EffectHandler<CounterEffect, CounterMessage> {
  CounterEffectHandler(this._storage);

  final FakeStorage _storage;

  @override
  Future<void> call(
    CounterEffect effect,
    MsgEmitter<CounterMessage> emit,
  ) async {
    switch (effect) {
      case LoadCount():
        try {
          final count = await _storage.load();
          if (count != null) {
            emit(CountLoaded(count));
          } else {
            emit(CountLoaded(0));
          }
        } on Exception catch (e) {
          emit(ErrorOccurred(e.toString()));
        }

      case SaveCount(:final count):
        try {
          await _storage.save(count);
          emit(CountSaved(count));
        } on Exception catch (e) {
          emit(ErrorOccurred(e.toString()));
        }

      case LogMessage(:final message):
        // This is a fire-and-forget effect - no message emitted back
        print('[EFFECT] $message');
    }
  }
}

// ==============================================================================
// Main
// ==============================================================================

Future<void> main() async {
  print('=== Puer Counter Example ===\n');

  // Create storage
  final storage = FakeStorage();

  // Create feature
  final feature = Feature<CounterState, CounterMessage, CounterEffect>(
    initialState: const CounterState(count: 0, isLoading: false),
    update: counterUpdate,
    effectHandlers: [CounterEffectHandler(storage)],
    initialEffects: [
      LogMessage('Feature created'),
      LoadCount(), // Load saved value on startup
    ],
  );

  // Listen to transitions for debugging/logging
  // This shows the complete flow: message → state change → effects
  feature.transitions.listen((transition) {
    print('\n--- Transition ---');
    print('Before:  ${transition.stateBefore}');
    print('Message: ${transition.message}');
    print('After:   ${transition.stateAfter ?? '(no change)'}');
    if (transition.effects.isNotEmpty) {
      print('Effects: ${transition.effects}');
    }
    print('------------------');
  });

  // Listen to state changes for UI updates
  feature.stateStream.listen((state) {
    print('→ State updated: $state');
  });

  // Initialize the feature (triggers initialEffects)
  await feature.init();

  // Wait for initial load to complete
  await Future<void>.delayed(const Duration(milliseconds: 800));

  print('\n=== User interactions ===\n');

  // Simulate user interactions
  feature.accept(Increment());
  await Future<void>.delayed(const Duration(milliseconds: 500));

  feature.accept(Increment());
  await Future<void>.delayed(const Duration(milliseconds: 500));

  feature.accept(Decrement());
  await Future<void>.delayed(const Duration(milliseconds: 500));

  feature.accept(Reset());
  await Future<void>.delayed(const Duration(milliseconds: 500));

  // Load saved value again
  print('\n=== Loading saved value ===\n');
  feature.accept(LoadSaved());
  await Future<void>.delayed(const Duration(milliseconds: 800));

  print('\n=== Cleaning up ===\n');
  await feature.dispose();

  print('Done!');
}
