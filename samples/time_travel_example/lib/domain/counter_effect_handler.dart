import 'package:flutter/foundation.dart';
import 'package:puer/puer.dart';

import '../data/counter_storage.dart';
import 'effect/counter_effect.dart';
import 'message/counter_message.dart';

final class CounterEffectHandler
    implements EffectHandler<CounterEffect, CounterMessage> {
  CounterEffectHandler(this._storage);

  final CounterStorage _storage;

  @override
  Future<void> call(
    CounterEffect effect,
    MsgEmitter<CounterMessage> emit,
  ) async {
    switch (effect) {
      case LoadCounterEffect():
        try {
          final count = await _storage.getValue();
          if (count != null) {
            emit(CounterMessage.loadSuccessful(value: count));
          } else {
            emit(const CounterMessage.loadFailed());
          }
        } on Exception catch (e) {
          debugPrint('Error during loading: $e');
          emit(const CounterMessage.loadFailed());
        }
      case SaveCounterEffect():
        try {
          await _storage.saveValue(effect.value);
        } on Exception catch (e) {
          debugPrint('Error during saving: $e');
        }
    }
  }
}
