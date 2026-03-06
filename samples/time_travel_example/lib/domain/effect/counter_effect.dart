import 'package:freezed_annotation/freezed_annotation.dart';

part 'counter_effect.freezed.dart';

@freezed
@immutable
sealed class CounterEffect with _$CounterEffect {
  const factory CounterEffect.loadCounter() = LoadCounterEffect;

  const factory CounterEffect.saveCounter({required int value}) =
      SaveCounterEffect;
}
