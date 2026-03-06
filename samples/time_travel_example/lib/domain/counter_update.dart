import 'package:puer/puer.dart';

import 'effect/counter_effect.dart';
import 'message/counter_message.dart';
import 'state/counter_state.dart';

Next<CounterState, CounterEffect> counterUpdate(
  CounterState state,
  CounterMessage message,
) => switch (message) {
  IncrementMessage() => next(
    state: state.copyWith(count: state.count + 1),
    effects: [CounterEffect.saveCounter(value: state.count + 1)],
  ),
  DecrementMessage() => next(
    state: state.copyWith(count: state.count - 1),
    effects: [CounterEffect.saveCounter(value: state.count - 1)],
  ),
  RequestLoadingMessage() => next(
    state: state.copyWith(status: CounterStatus.loading),
    effects: [const CounterEffect.loadCounter()],
  ),
  LoadSuccessfulMessage() => next(
    state: state.copyWith(count: message.value, status: CounterStatus.active),
  ),
  LoadFailedMessage() => next(
    state: state.copyWith(status: CounterStatus.active),
  ),
};
