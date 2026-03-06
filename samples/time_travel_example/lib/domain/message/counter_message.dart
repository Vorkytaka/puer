import 'package:freezed_annotation/freezed_annotation.dart';

part 'counter_message.freezed.dart';

@freezed
@immutable
sealed class CounterMessage with _$CounterMessage {
  const factory CounterMessage.increment() = IncrementMessage;

  const factory CounterMessage.decrement() = DecrementMessage;

  const factory CounterMessage.requestLoading() = RequestLoadingMessage;

  const factory CounterMessage.loadSuccessful({required int value}) =
      LoadSuccessfulMessage;

  const factory CounterMessage.loadFailed() = LoadFailedMessage;
}
