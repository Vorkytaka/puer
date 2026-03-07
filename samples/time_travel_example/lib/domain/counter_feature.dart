import 'package:puer_time_travel/puer_time_travel.dart';

import '../data/counter_storage.dart';
import 'counter_effect_handler.dart';
import 'counter_update.dart';
import 'effect/counter_effect.dart';
import 'message/counter_message.dart';
import 'state/counter_state.dart';

export 'counter_effect_handler.dart';
export 'effect/counter_effect.dart';
export 'message/counter_message.dart';
export 'state/counter_state.dart';

typedef CounterFeature = Feature<CounterState, CounterMessage, CounterEffect>;

CounterFeature createCounterFeature({required CounterStorage storage}) =>
    TimeTravelFeature<CounterState, CounterMessage, CounterEffect>(
      name: 'CounterFeature',
      initialState: CounterState.initial,
      update: counterUpdate,
      effectHandlers: [CounterEffectHandler(storage)],
      initialEffects: const [CounterEffect.loadCounter()],
    );
