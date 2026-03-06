import 'package:freezed_annotation/freezed_annotation.dart';

part 'counter_state.freezed.dart';

enum CounterStatus { active, loading }

@freezed
@immutable
class CounterState with _$CounterState {
  const factory CounterState({
    required int count,
    required CounterStatus status,
  }) = _CounterState;

  static const initial = CounterState(count: 0, status: CounterStatus.active);
}
